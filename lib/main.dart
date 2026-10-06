import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/di/injection.dart';
import 'core/env/app_env.dart';
import 'core/widgets/config_missing_app.dart';
import 'features/workouts/domain/repositories/workout_sync_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  final env = AppEnv.fromEnvironment();
  if (!env.hasBackend) {
    runApp(ConfigMissingApp(missingKeys: env.missingKeys));
    return;
  }
  if (env.mapsApiKey.isEmpty) {
    debugPrint('MAPS_API_KEY is empty: the map will not load.');
  }

  // Restores the previous session and handles magic-link deep links.
  await Supabase.initialize(
    url: env.supabaseUrl,
    publishableKey: env.supabaseKey,
  );

  await configureDependencies(env, Supabase.instance.client);
  // Upload workouts finished while offline (no-op when signed out).
  unawaited(getIt<WorkoutSyncRepository>().syncPending());
  runApp(PulseRouteApp(themeCubit: getIt(), sessionBloc: getIt()));
}
