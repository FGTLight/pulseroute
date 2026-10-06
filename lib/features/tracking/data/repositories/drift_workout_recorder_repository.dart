import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/domain/activity_type.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../workouts/domain/entities/workout.dart';
import '../../../workouts/domain/services/route_simplifier.dart';
import '../../domain/entities/active_workout.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/entities/workout_stats.dart';
import '../../domain/repositories/workout_recorder_repository.dart';
import 'local_workout_mapper.dart';

/// [WorkoutRecorderRepository] backed by the on-device SQLite database.
class DriftWorkoutRecorderRepository implements WorkoutRecorderRepository {
  DriftWorkoutRecorderRepository(this._db);

  final AppDatabase _db;

  static const _finished = 'finished';

  @override
  Future<Result<ActiveWorkout?>> loadActive() => _guard(() async {
    final row =
        await (_db.select(_db.localWorkouts)
              ..where((w) => w.status.equals(_finished).not())
              ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;

    final points = await LocalWorkoutMapper.pointsOf(_db, row.id);
    return ActiveWorkout(
      id: row.id,
      activity: ActivityType.fromName(row.activity),
      startedAt: row.startedAt,
      status: row.status == ActiveWorkoutStatus.recording.name
          ? ActiveWorkoutStatus.recording
          : ActiveWorkoutStatus.paused,
      activeDuration: Duration(milliseconds: row.activeDurationMs),
      resumedAt: row.resumedAt,
      segment: row.segment,
      points: points,
    );
  });

  @override
  Future<Result<void>> saveState(ActiveWorkout workout) => _guard(
    () => _db
        .into(_db.localWorkouts)
        .insertOnConflictUpdate(
          LocalWorkoutsCompanion.insert(
            id: workout.id,
            activity: workout.activity.name,
            startedAt: workout.startedAt,
            status: workout.status.name,
            activeDurationMs: Value(workout.activeDuration.inMilliseconds),
            resumedAt: Value(workout.resumedAt),
            segment: Value(workout.segment),
          ),
        ),
  );

  @override
  Future<Result<void>> appendPoint(String workoutId, TrackPoint point) =>
      _guard(
        () => _db
            .into(_db.localTrackPoints)
            .insert(
              LocalTrackPointsCompanion.insert(
                workoutId: workoutId,
                segment: point.segment,
                lat: point.lat,
                lng: point.lng,
                accuracyM: point.accuracyM,
                altitudeM: Value(point.altitudeM),
                speedMps: Value(point.speedMps),
                recordedAt: point.timestamp,
              ),
            ),
      );

  @override
  Future<Result<Workout>> finish(
    ActiveWorkout workout, {
    required WorkoutStats stats,
    required List<Duration> splits,
    required DateTime endedAt,
  }) => _guard(() async {
    await (_db.update(
      _db.localWorkouts,
    )..where((w) => w.id.equals(workout.id))).write(
      LocalWorkoutsCompanion(
        status: const Value(_finished),
        endedAt: Value(endedAt),
        resumedAt: const Value(null),
        activeDurationMs: Value(stats.duration.inMilliseconds),
        distanceM: Value(stats.distanceM),
        elevationGainM: Value(stats.elevationGainM),
        maxSpeedMps: Value(stats.maxSpeedMps),
        splitsJson: Value(
          jsonEncode([for (final s in splits) s.inMilliseconds]),
        ),
        previewJson: Value(
          LocalWorkoutMapper.encodePreview(
            simplifyRoute([for (final p in workout.points) p.point]),
          ),
        ),
      ),
    );
    return Workout(
      id: workout.id,
      activity: workout.activity,
      startedAt: workout.startedAt,
      endedAt: endedAt,
      duration: stats.duration,
      distanceM: stats.distanceM,
      elevationGainM: stats.elevationGainM,
      maxSpeedMps: stats.maxSpeedMps,
      splits: splits,
      route: [for (final p in workout.points) p.point],
    );
  });

  @override
  Future<Result<void>> discard(String workoutId) => _guard(
    () => (_db.delete(
      _db.localWorkouts,
    )..where((w) => w.id.equals(workoutId))).go(),
  );

  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on Object catch (error) {
      return Err(
        CacheFailure('Could not save the workout on the device: $error'),
      );
    }
  }
}
