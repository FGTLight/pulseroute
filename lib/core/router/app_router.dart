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
import '../../features/incidents/presentation/bloc/incidents_bloc.dart';
import '../../features/incidents/presentation/cubit/proximity_alert_cubit.dart';
import '../../features/incidents/presentation/cubit/report_incident_cubit.dart';
import '../../features/incidents/presentation/screens/incidents_screen.dart';
import '../../features/incidents/presentation/screens/report_incident_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/cubit/account_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tracking/presentation/bloc/tracking_bloc.dart';
import '../../features/tracking/presentation/screens/track_screen.dart';
import '../../features/workouts/domain/entities/workout.dart';
import '../../features/workouts/presentation/cubit/history_cubit.dart';
import '../../features/workouts/presentation/cubit/workout_detail_cubit.dart';
import '../../features/workouts/presentation/screens/history_screen.dart';
import '../../features/workouts/presentation/screens/workout_detail_screen.dart';
import '../../features/workouts/presentation/screens/workout_summary_screen.dart';
import '../connectivity/connectivity_cubit.dart';
import '../di/injection.dart';
import '../domain/geo_point.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

/// Builds the app's [GoRouter].
///
/// Screen-scoped blocs are created here from [getIt] (the router is part of
/// the composition root), so screens only read them from the context.
GoRouter createRouter({
  required SessionBloc session,
  required SettingsCubit settings,
  Listenable? refreshListenable,
}) {
  // One key per router instance, so several apps can coexist in tests.
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.track,
    refreshListenable: refreshListenable,
    redirect: (context, state) => appRedirect(
      session: session.state,
      onboardingDone: settings.state.onboardingDone,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) =>
            OnboardingScreen(onDone: settings.completeOnboarding),
      ),
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
        // These blocs live above the tabs, so a workout keeps recording
        // (and alerting) while the user browses other tabs.
        builder: (context, state, shell) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: getIt<TrackingBloc>()),
            BlocProvider.value(value: getIt<IncidentsBloc>()),
            BlocProvider.value(value: getIt<ProximityAlertCubit>()),
            BlocProvider.value(value: getIt<ConnectivityCubit>()),
          ],
          child: AppShell(navigationShell: shell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.track,
                builder: (context, state) => const TrackScreen(),
                routes: [
                  GoRoute(
                    path: 'summary',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) =>
                        WorkoutSummaryScreen(workout: state.extra! as Workout),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.incidents,
                builder: (context, state) => const IncidentsScreen(),
                routes: [
                  GoRoute(
                    path: 'report',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<ReportIncidentCubit>(
                        param1: state.extra! as GeoPoint,
                      ),
                      child: const ReportIncidentScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<HistoryCubit>(),
                  child: const HistoryScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => BlocProvider(
                      create: (_) {
                        final cubit = getIt<WorkoutDetailCubit>();
                        unawaited(cubit.load(state.pathParameters['id']!));
                        return cubit;
                      },
                      child: const WorkoutDetailScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<AccountCubit>(),
                  child: const SettingsScreen(),
                ),
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
///
/// Order: onboarding (first launch) → sign in → the app.
String? appRedirect({
  required SessionState session,
  required bool onboardingDone,
  required String location,
}) {
  if (!onboardingDone) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }
  final onPublicRoute = AppRoutes.public.contains(location);
  if (!session.isAuthenticated) {
    return onPublicRoute && location != AppRoutes.onboarding
        ? null
        : AppRoutes.signIn;
  }
  if (onPublicRoute) return AppRoutes.track;
  return null;
}
