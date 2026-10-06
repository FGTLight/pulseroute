import 'package:flutter/material.dart';

import '../../../../core/widgets/state_views.dart';

/// Past workouts with route previews. Built in step 7.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const EmptyState(
        icon: Icons.history_rounded,
        title: 'No workouts yet',
        message: 'Your finished runs and rides will show up here.',
      ),
    );
  }
}
