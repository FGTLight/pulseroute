import 'package:flutter/material.dart';

import '../../../../core/widgets/state_views.dart';

/// Nearby community-reported incidents. Built in step 5.
class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incidents')),
      body: const EmptyState(
        icon: Icons.report_rounded,
        title: 'No incidents nearby',
        message: 'Reports from the community will appear here.',
      ),
    );
  }
}
