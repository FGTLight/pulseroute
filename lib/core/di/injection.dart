import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/data/repositories/supabase_profile_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/profile_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/auth/presentation/cubit/profile_cubit.dart';
import '../../features/auth/presentation/cubit/sign_in_cubit.dart';
import '../../features/auth/presentation/cubit/sign_up_cubit.dart';
import '../../features/incidents/data/repositories/image_picker_photo_repository.dart';
import '../../features/incidents/data/repositories/supabase_incident_repository.dart';
import '../../features/incidents/domain/repositories/incident_repository.dart';
import '../../features/incidents/domain/usecases/incident_usecases.dart';
import '../../features/incidents/presentation/bloc/incidents_bloc.dart';
import '../../features/incidents/presentation/cubit/report_incident_cubit.dart';
import '../../features/settings/data/shared_prefs_settings_repository.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/settings/presentation/cubit/theme_cubit.dart';
import '../../features/tracking/data/repositories/drift_workout_recorder_repository.dart';
import '../../features/tracking/data/repositories/geolocator_location_repository.dart';
import '../../features/tracking/domain/repositories/location_repository.dart';
import '../../features/tracking/domain/repositories/workout_recorder_repository.dart';
import '../../features/tracking/domain/usecases/finish_workout.dart';
import '../../features/tracking/presentation/bloc/tracking_bloc.dart';
import '../../features/workouts/data/datasources/workout_remote_data_source.dart';
import '../../features/workouts/data/repositories/workout_sync_repository_impl.dart';
import '../../features/workouts/domain/repositories/workout_sync_repository.dart';
import '../database/app_database.dart';
import '../domain/geo_point.dart';
import '../env/app_env.dart';

/// Service locator used to wire the app together.
///
/// Only the composition root (this file, `main.dart` and the router) reads
/// from [getIt]; everything else receives its dependencies via constructors,
/// which keeps classes easy to test.
final GetIt getIt = GetIt.instance;

/// Registers every dependency. Call once, before `runApp`.
Future<void> configureDependencies(AppEnv env, SupabaseClient supabase) async {
  final prefs = await SharedPreferences.getInstance();

  getIt
    // Core
    ..registerSingleton<AppEnv>(env)
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<SupabaseClient>(supabase)
    ..registerSingleton<AppDatabase>(
      AppDatabase(),
      dispose: (db) => db.close(),
    );

  _registerSettings();
  _registerAuth();
  _registerTracking();
  _registerIncidents();
}

void _registerSettings() {
  getIt
    ..registerLazySingleton<SettingsRepository>(
      () => SharedPrefsSettingsRepository(getIt()),
    )
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit(getIt()));
}

void _registerAuth() {
  getIt
    // Data
    ..registerLazySingleton<AuthRepository>(
      () => SupabaseAuthRepository(getIt<SupabaseClient>().auth),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => SupabaseProfileRepository(getIt()),
    )
    // Domain
    ..registerFactory(() => SignInWithPassword(getIt()))
    ..registerFactory(() => SignUpWithEmail(getIt()))
    ..registerFactory(() => SendMagicLink(getIt()))
    ..registerFactory(() => SignOut(getIt()))
    ..registerFactory(() => GetMyProfile(getIt()))
    ..registerFactory(() => UpdateProfile(getIt()))
    // Presentation
    ..registerLazySingleton<SessionBloc>(
      () => SessionBloc(repository: getIt(), signOut: getIt()),
    )
    ..registerFactory(
      () => SignInCubit(signInWithPassword: getIt(), sendMagicLink: getIt()),
    )
    ..registerFactory(() => SignUpCubit(signUp: getIt()))
    ..registerFactory(
      () => ProfileCubit(getMyProfile: getIt(), updateProfile: getIt()),
    );
}

void _registerTracking() {
  getIt
    // Data
    ..registerLazySingleton<LocationRepository>(
      GeolocatorLocationRepository.new,
    )
    ..registerLazySingleton<WorkoutRecorderRepository>(
      () => DriftWorkoutRecorderRepository(getIt()),
    )
    ..registerLazySingleton(() => WorkoutRemoteDataSource(getIt()))
    ..registerLazySingleton<WorkoutSyncRepository>(
      () => WorkoutSyncRepositoryImpl(getIt(), getIt()),
    )
    // Domain
    ..registerFactory(() => FinishWorkout(recorder: getIt(), sync: getIt()))
    // Presentation: one bloc for the whole app; it restores any workout
    // interrupted by the app being killed as soon as it is created.
    ..registerLazySingleton<TrackingBloc>(
      () => TrackingBloc(
        location: getIt(),
        recorder: getIt(),
        finishWorkout: getIt(),
        newId: const Uuid().v4,
      )..add(const TrackingRecoveryRequested()),
      dispose: (bloc) => bloc.close(),
    );
}

void _registerIncidents() {
  getIt
    // Data
    ..registerLazySingleton<IncidentRepository>(
      () => SupabaseIncidentRepository(getIt()),
    )
    ..registerLazySingleton<PhotoRepository>(ImagePickerPhotoRepository.new)
    // Domain
    ..registerFactory(() => GetNearbyIncidents(getIt()))
    ..registerFactory(() => ReportIncident(getIt()))
    ..registerFactory(() => VoteOnIncident(getIt()))
    // Presentation
    ..registerLazySingleton<IncidentsBloc>(
      () => IncidentsBloc(
        getNearby: getIt(),
        vote: getIt(),
        repository: getIt(),
        locate: getIt<LocationRepository>().currentPosition,
      )..add(const IncidentsStarted()),
      dispose: (bloc) => bloc.close(),
    )
    ..registerFactoryParam<ReportIncidentCubit, GeoPoint, void>(
      (location, _) => ReportIncidentCubit(
        location: location,
        reportIncident: getIt(),
        photos: getIt(),
      ),
    );
}
