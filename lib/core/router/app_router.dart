import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/auth/presentation/cubit/profile_cubit.dart';
import '../../features/auth/presentation/cubit/sign_in_cubit.dart';
import '../../features/auth/presentation/cubit/sign_up_cubit.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/incidents/presentation/screens/incidents_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tracking/presentation/screens/track_screen.dart';
import '../../features/workouts/presentation/screens/history_screen.dart';
import '../di/injection.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

/// Builds the app's [GoRouter].
///
/// Screen-scoped blocs are created here from [getIt] (the router is part of
/// the composition root), so screens only read them from the context.
GoRouter createRouter({
  required SessionBloc session,
  Listenable? refreshListenable,
}) {
  // One key per router instance, so several apps can coexist in tests.
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.track,
    refreshListenable: refreshListenable,
    redirect: (context, state) =>
        authRedirect(session.state, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SignInCubit>(),
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SignUpCubit>(),
          child: const SignUpScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.track,
                builder: (context, state) => const TrackScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.incidents,
                builder: (context, state) => const IncidentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => BlocProvider(
                      create: (_) {
                        final cubit = getIt<ProfileCubit>();
                        unawaited(cubit.load());
                        return cubit;
                      },
                      child: const ProfileScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Where to send the user, or `null` to stay. Pure, so it is unit tested.
String? authRedirect(SessionState session, String location) {
  final onPublicRoute = AppRoutes.public.contains(location);
  if (!session.isAuthenticated) return onPublicRoute ? null : AppRoutes.signIn;
  if (onPublicRoute) return AppRoutes.track;
  return null;
}
