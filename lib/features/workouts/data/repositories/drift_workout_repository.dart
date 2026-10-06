import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/domain/geo_point.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../tracking/data/repositories/local_workout_mapper.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_preview.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/services/route_simplifier.dart';
import '../datasources/workout_remote_data_source.dart';

/// Offline-first [WorkoutRepository]: reads from SQLite, imports from and
/// deletes on Supabase.
class DriftWorkoutRepository implements WorkoutRepository {
  DriftWorkoutRepository(this._db, this._remote);

  final AppDatabase _db;
  final WorkoutRemoteDataSource _remote;

  SimpleSelectStatement<$LocalWorkoutsTable, LocalWorkoutRow> get _finished =>
      _db.select(_db.localWorkouts)
        ..where((w) => w.status.equals('finished'))
        ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]);

  @override
  Stream<List<WorkoutPreview>> watchHistory() =>
      _finished.watch().asyncMap((rows) async {
        return [
          for (final row in rows)
            LocalWorkoutMapper.toPreview(row, await _previewOf(row)),
        ];
      });

  /// Stored preview, or computed from the points for workouts recorded
  /// before schema version 2.
  Future<List<GeoPoint>> _previewOf(LocalWorkoutRow row) async {
    final stored = LocalWorkoutMapper.decodePoints(
      row.previewJson.isEmpty ? null : _decode(row.previewJson),
    );
    if (stored.isNotEmpty) return stored;
    final points = await LocalWorkoutMapper.pointsOf(_db, row.id);
    return simplifyRoute([for (final p in points) p.point]);
  }

  static Object? _decode(String json) => LocalWorkoutMapper.decodeJson(json);

  @override
  Future<Result<Workout>> getWorkout(String id) async {
    try {
      final row = await (_db.select(
        _db.localWorkouts,
      )..where((w) => w.id.equals(id))).getSingleOrNull();
      if (row == null) return const Err(NotFoundFailure('Workout not found.'));
      final points = await LocalWorkoutMapper.pointsOf(_db, id);
      return Success(LocalWorkoutMapper.toWorkout(row, points));
    } on Object catch (error) {
      return Err(CacheFailure('Could not read the workout: $error'));
    }
  }

  @override
  Future<Result<int>> refreshFromServer() async {
    if (!_remote.isSignedIn) return const Success(0);
    try {
      final rows = await _remote.fetchAll();
      final known = {
        for (final w in await _db.select(_db.localWorkouts).get()) w.id,
      };
      var imported = 0;
      for (final row in rows) {
        final id = row['id'] as String;
        if (known.contains(id)) continue;
        await _import(row);
        imported++;
      }
      return Success(imported);
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }

  /// Stores a server workout locally. The server keeps the route geometry
  /// but not per-point times, so timestamps are spread evenly over the
  /// workout (only used for drawing; stats come from the stored totals).
  Future<void> _import(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final startedAt = DateTime.parse(row['started_at'] as String).toLocal();
    final endedAt = DateTime.parse(row['ended_at'] as String).toLocal();
    final route = LocalWorkoutMapper.decodePoints(row['route_points']);
    final span = endedAt.difference(startedAt);

    await _db.transaction(() async {
      await _db
          .into(_db.localWorkouts)
          .insert(
            LocalWorkoutsCompanion.insert(
              id: id,
              activity: row['activity'] as String,
              startedAt: startedAt,
              endedAt: Value(endedAt),
              status: 'finished',
              activeDurationMs: Value(
                ((row['duration_s'] as num?) ?? 0).toInt() * 1000,
              ),
              distanceM: Value(((row['distance_m'] as num?) ?? 0).toDouble()),
              elevationGainM: Value(
                ((row['elevation_gain_m'] as num?) ?? 0).toDouble(),
              ),
              maxSpeedMps: Value(
                ((row['max_speed_mps'] as num?) ?? 0).toDouble(),
              ),
              splitsJson: Value(
                LocalWorkoutMapper.encodeSplitSeconds(
                  (row['splits_s'] as List<dynamic>?) ?? const [],
                ),
              ),
              previewJson: Value(
                LocalWorkoutMapper.encodePreview(simplifyRoute(route)),
              ),
              synced: const Value(true),
            ),
          );
      await _db.batch((b) {
        b.insertAll(_db.localTrackPoints, [
          for (var i = 0; i < route.length; i++)
            LocalTrackPointsCompanion.insert(
              workoutId: id,
              segment: 0,
              lat: route[i].lat,
              lng: route[i].lng,
              accuracyM: 0,
              recordedAt: startedAt.add(
                route.length < 2
                    ? Duration.zero
                    : span * (i / (route.length - 1)),
              ),
            ),
        ]);
      });
    });
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final row = await (_db.select(
        _db.localWorkouts,
      )..where((w) => w.id.equals(id))).getSingleOrNull();
      if (row?.synced ?? false) await _remote.delete(id);
      await (_db.delete(_db.localWorkouts)..where((w) => w.id.equals(id))).go();
      return const Success(null);
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }
}
