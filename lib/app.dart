import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/stream_listenable.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/session_bloc.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';

/// Root widget: global blocs, theme and router.
class PulseRouteApp extends StatefulWidget {
  const PulseRouteApp({
    required this.themeCubit,
    required this.sessionBloc,
    super.key,
  });

  final ThemeCubit themeCubit;
  final SessionBloc sessionBloc;

  @override
  State<PulseRouteApp> createState() => _PulseRouteAppState();
}

class _PulseRouteAppState extends State<PulseRouteApp> {
  late final _refresh = StreamListenable(widget.sessionBloc.stream);
  late final GoRouter _router = createRouter(
    session: widget.sessionBloc,
    refreshListenable: _refresh,
  );

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.themeCubit),
        BlocProvider.value(value: widget.sessionBloc),
      ],
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
