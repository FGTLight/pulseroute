import '../../../../core/errors/result.dart';
import '../entities/workout.dart';
import '../entities/workout_preview.dart';

/// Finished workouts. The device database is the source of truth (it works
/// offline); [refreshFromServer] imports workouts recorded on other devices.
abstract interface class WorkoutRepository {
  /// Finished workouts, newest first, updated live.
  Stream<List<WorkoutPreview>> watchHistory();

  /// A workout with its full route.
  Future<Result<Workout>> getWorkout(String id);

  /// Downloads server workouts missing on this device. Returns how many
  /// were imported.
  Future<Result<int>> refreshFromServer();

  /// Deletes the workout on the device and, if uploaded, on the server.
  Future<Result<void>> delete(String id);
}
