import '../../../../core/errors/result.dart';
import '../../../workouts/domain/entities/workout.dart';
import '../entities/active_workout.dart';
import '../entities/track_point.dart';
import '../entities/workout_stats.dart';

/// Local, offline-first storage of the workout being recorded.
///
/// Every call writes to disk immediately, so nothing is lost if the app is
/// killed or the phone runs out of battery.
abstract interface class WorkoutRecorderRepository {
  /// The unfinished workout left from a previous session, if any.
  Future<Result<ActiveWorkout?>> loadActive();

  /// Creates a new workout or updates its status / clock fields.
  Future<Result<void>> saveState(ActiveWorkout workout);

  Future<Result<void>> appendPoint(String workoutId, TrackPoint point);

  /// Marks the workout as finished with its final numbers. It stays on the
  /// device as "pending sync" until uploaded.
  Future<Result<Workout>> finish(
    ActiveWorkout workout, {
    required WorkoutStats stats,
    required List<Duration> splits,
    required DateTime endedAt,
  });

  /// Deletes an unfinished workout and its points.
  Future<Result<void>> discard(String workoutId);
}
