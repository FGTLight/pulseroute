import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/domain/geo_point.dart';
import '../../domain/entities/workout.dart';

/// Talks to the `workouts` table in Supabase.
class WorkoutRemoteDataSource {
  WorkoutRemoteDataSource(this._client);

  final SupabaseClient _client;

  bool get isSignedIn => _client.auth.currentUser != null;

  /// Inserts the workout, ignoring it if it was already uploaded (the id is
  /// generated on the device, so retries are idempotent).
  Future<void> upsert(Workout workout) => _client
      .from('workouts')
      .upsert(toRow(workout), onConflict: 'id', ignoreDuplicates: true);

  /// Row sent to Postgres. The route is sent as EWKT, which PostGIS parses
  /// into a `geography(LineString)`.
  static Map<String, dynamic> toRow(Workout workout) => {
    'id': workout.id,
    'activity': workout.activity.name,
    'started_at': workout.startedAt.toUtc().toIso8601String(),
    'ended_at': workout.endedAt.toUtc().toIso8601String(),
    'duration_s': workout.duration.inSeconds,
    'distance_m': workout.distanceM,
    'elevation_gain_m': workout.elevationGainM,
    'avg_speed_mps': workout.avgSpeedMps,
    'max_speed_mps': workout.maxSpeedMps,
    'splits_s': [for (final s in workout.splits) s.inSeconds],
    'route': lineStringEwkt(workout.route),
  };

  /// `SRID=4326;LINESTRING(lng lat, ...)`, or `null` with fewer than two
  /// points (PostGIS rejects such lines).
  static String? lineStringEwkt(List<GeoPoint> route) {
    if (route.length < 2) return null;
    final coords = route
        .map((p) => '${p.lng.toStringAsFixed(6)} ${p.lat.toStringAsFixed(6)}')
        .join(',');
    return 'SRID=4326;LINESTRING($coords)';
  }
}
