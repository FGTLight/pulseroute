import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'offline_banner.dart';

/// Hosts the main tabs: a bottom [NavigationBar] on phones and a
/// [NavigationRail] on tablets and in landscape.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Width from which the navigation rail replaces the bottom bar.
  static const railBreakpoint = 640.0;

  static const List<(IconData, IconData, String)> destinations = [
    (Icons.directions_run_outlined, Icons.directions_run_rounded, 'Track'),
    (Icons.report_outlined, Icons.report_rounded, 'Incidents'),
    (Icons.history_rounded, Icons.history_rounded, 'History'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  void _onSelect(int index) => navigationShell.goBranch(
    index,
    // Tapping the active tab again returns to its first page.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.9,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: OfflineAware(child: navigationShell)),
          ],
        ),
      );
    }

    return Scaffold(
      body: OfflineAware(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
