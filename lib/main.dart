import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/di/injection.dart';
import 'core/env/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  final env = AppEnv.fromEnvironment();
  if (!env.isComplete) {
    debugPrint(
      'Missing configuration: ${env.missingKeys.join(', ')}. '
      'Run with --dart-define-from-file=.env (see .env.example).',
    );
  }

  await configureDependencies(env);
  runApp(PulseRouteApp(themeCubit: getIt()));
}
