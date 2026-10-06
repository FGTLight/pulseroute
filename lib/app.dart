import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/stream_listenable.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/session_bloc.dart';
import 'features/settings/domain/app_settings.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

/// Root widget: global blocs, theme and router.
class PulseRouteApp extends StatefulWidget {
  const PulseRouteApp({
    required this.settingsCubit,
    required this.sessionBloc,
    super.key,
  });

  final SettingsCubit settingsCubit;
  final SessionBloc sessionBloc;

  @override
  State<PulseRouteApp> createState() => _PulseRouteAppState();
}

class _PulseRouteAppState extends State<PulseRouteApp> {
  // Redirects depend on the session and on the onboarding flag.
  late final _refresh = StreamListenable([
    widget.sessionBloc.stream,
    widget.settingsCubit.stream.map((s) => s.onboardingDone).distinct(),
  ]);
  late final GoRouter _router = createRouter(
    session: widget.sessionBloc,
    settings: widget.settingsCubit,
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
        BlocProvider.value(value: widget.settingsCubit),
        BlocProvider.value(value: widget.sessionBloc),
      ],
      child: BlocBuilder<SettingsCubit, AppSettings>(
        buildWhen: (a, b) => a.themeMode != b.themeMode,
        builder: (context, settings) => MaterialApp.router(
          title: 'PulseRoute',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
