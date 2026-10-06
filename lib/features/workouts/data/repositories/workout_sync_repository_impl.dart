import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../tracking/data/repositories/local_workout_mapper.dart';
import '../../domain/repositories/workout_sync_repository.dart';
import '../datasources/workout_remote_data_source.dart';

/// Uploads finished local workouts to Supabase and marks them as synced.
class WorkoutSyncRepositoryImpl implements WorkoutSyncRepository {
  WorkoutSyncRepositoryImpl(this._db, this._remote);

  final AppDatabase _db;
  final WorkoutRemoteDataSource _remote;

  bool _running = false;

  @override
  Future<Result<int>> syncPending() async {
    // Avoid overlapping runs (e.g. finish + app resume at the same time).
    if (_running || !_remote.isSignedIn) return const Success(0);
    _running = true;
    try {
      final pending =
          await (_db.select(_db.localWorkouts)..where(
                (w) => w.status.equals('finished') & w.synced.equals(false),
              ))
              .get();

      var uploaded = 0;
      for (final row in pending) {
        final points = await LocalWorkoutMapper.pointsOf(_db, row.id);
        await _remote.upsert(LocalWorkoutMapper.toWorkout(row, points));
        await (_db.update(_db.localWorkouts)..where((w) => w.id.equals(row.id)))
            .write(const LocalWorkoutsCompanion(synced: Value(true)));
        uploaded++;
      }
      return Success(uploaded);
    } on Object catch (error) {
      return Err(mapError(error));
    } finally {
      _running = false;
    }
  }
}
