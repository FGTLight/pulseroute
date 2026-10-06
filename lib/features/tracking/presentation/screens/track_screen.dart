import 'package:flutter/material.dart';

import '../../../../core/widgets/state_views.dart';

/// Live workout screen: map, route polyline and stats. Built in step 4.
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PulseRoute')),
      body: const EmptyState(
        icon: Icons.directions_run_rounded,
        title: 'Ready when you are',
        message: 'Start a run or ride to map your route in real time.',
      ),
    );
  }
}
