import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';

/// Root widget: global blocs, theme and router.
class PulseRouteApp extends StatefulWidget {
  const PulseRouteApp({required this.themeCubit, super.key});

  final ThemeCubit themeCubit;

  @override
  State<PulseRouteApp> createState() => _PulseRouteAppState();
}

class _PulseRouteAppState extends State<PulseRouteApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          title: 'PulseRoute',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
