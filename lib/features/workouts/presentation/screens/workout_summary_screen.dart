import 'package:flutter/material.dart';

import '../../domain/entities/workout.dart';
import '../widgets/workout_summary_view.dart';

/// Shown right after finishing a workout.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({required this.workout, super.key});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Great job!'),
        leading: IconButton(
          tooltip: 'Done',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WorkoutSummaryView(workout: workout),
    );
  }
}
