import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/domain/activity_type.dart';
import '../../../workouts/domain/entities/workout.dart';
import '../../domain/entities/track_point.dart';

/// Converts local database rows into domain objects.
abstract final class LocalWorkoutMapper {
  /// Points of a workout in recording order.
  static Future<List<TrackPoint>> pointsOf(
    AppDatabase db,
    String workoutId,
  ) async {
    final rows =
        await (db.select(db.localTrackPoints)
              ..where((p) => p.workoutId.equals(workoutId))
              ..orderBy([(p) => OrderingTerm.asc(p.id)]))
            .get();
    return [
      for (final r in rows)
        TrackPoint(
          lat: r.lat,
          lng: r.lng,
          timestamp: r.recordedAt,
          segment: r.segment,
          accuracyM: r.accuracyM,
          altitudeM: r.altitudeM,
          speedMps: r.speedMps,
        ),
    ];
  }

  /// A finished workout with its route.
  static Workout toWorkout(LocalWorkoutRow row, List<TrackPoint> points) =>
      Workout(
        id: row.id,
        activity: ActivityType.fromName(row.activity),
        startedAt: row.startedAt,
        endedAt: row.endedAt ?? row.startedAt,
        duration: Duration(milliseconds: row.activeDurationMs),
        distanceM: row.distanceM,
        elevationGainM: row.elevationGainM,
        maxSpeedMps: row.maxSpeedMps,
        splits: [
          for (final ms in jsonDecode(row.splitsJson) as List<dynamic>)
            Duration(milliseconds: (ms as num).toInt()),
        ],
        route: [for (final p in points) p.point],
        synced: row.synced,
      );
}
