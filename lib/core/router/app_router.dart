import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/incidents/presentation/screens/incidents_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tracking/presentation/screens/track_screen.dart';
import '../../features/workouts/presentation/screens/history_screen.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

/// Builds the app's [GoRouter].
///
/// [refreshListenable] re-runs redirects (e.g. when the auth state changes).
GoRouter createRouter({Listenable? refreshListenable}) {
  // One key per router instance, so several apps can coexist in tests.
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.track,
    refreshListenable: refreshListenable,
    routes: [
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
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
