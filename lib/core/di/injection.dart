import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
Future<void> configureDependencies(AppEnv env) async {
  final prefs = await SharedPreferences.getInstance();

  getIt
    // Core
    ..registerSingleton<AppEnv>(env)
    ..registerSingleton<SharedPreferences>(prefs)
    // Settings
    ..registerLazySingleton<SettingsRepository>(
      () => SharedPrefsSettingsRepository(getIt()),
    )
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit(getIt()));
}
