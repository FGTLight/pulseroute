import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/data/repositories/supabase_profile_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/profile_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/auth/presentation/cubit/profile_cubit.dart';
import '../../features/auth/presentation/cubit/sign_in_cubit.dart';
import '../../features/auth/presentation/cubit/sign_up_cubit.dart';
import '../../features/settings/data/shared_prefs_settings_repository.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/settings/presentation/cubit/theme_cubit.dart';
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
    ..registerSingleton<SupabaseClient>(supabase);

  _registerSettings();
  _registerAuth();
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
