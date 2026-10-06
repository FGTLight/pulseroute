import '../../../../core/errors/result.dart';

/// Uploads finished workouts that only exist on the device.
abstract interface class WorkoutSyncRepository {
  /// Uploads every pending workout. Returns how many were uploaded.
  ///
  /// Safe to call repeatedly: uploads are idempotent (the id is generated
  /// on the device), and failures leave workouts pending for the next try.
  Future<Result<int>> syncPending();
}
