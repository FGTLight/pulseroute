import 'dart:async';

import '../../../../core/errors/result.dart';
import '../../../workouts/domain/entities/workout.dart';
import '../../../workouts/domain/repositories/workout_sync_repository.dart';
import '../entities/active_workout.dart';
import '../repositories/workout_recorder_repository.dart';
import '../services/stats_accumulator.dart';

/// Finishes a workout: computes the final stats and splits, stores it on
/// the device and starts an upload in the background.
///
/// Saving locally is what matters for the user; the upload is retried later
/// if the phone is offline.
class FinishWorkout {
  const FinishWorkout({
    required WorkoutRecorderRepository recorder,
    required WorkoutSyncRepository sync,
  }) : _recorder = recorder,
       _sync = sync;

  final WorkoutRecorderRepository _recorder;
  final WorkoutSyncRepository _sync;

  Future<Result<Workout>> call(ActiveWorkout workout, DateTime now) async {
    final stats = StatsAccumulator.fromPoints(workout.points)
        .toStats(workout.elapsed(now));

    final result = await _recorder.finish(
      workout,
      stats: stats,
      splits: computeSplits(workout.points),
      endedAt: now,
    );
    if (result.isSuccess) unawaited(_sync.syncPending());
    return result;
  }
}
