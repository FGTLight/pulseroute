import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/ewkt.dart';
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

  /// The user's workouts, newest first. `route_points` is a computed field
  /// (see the workouts migration) that returns the route as JSON.
  Future<List<Map<String, dynamic>>> fetchAll() => _client
      .from('workouts')
      .select(
        'id, activity, started_at, ended_at, duration_s, distance_m, '
        'elevation_gain_m, max_speed_mps, splits_s, route_points',
      )
      .order('started_at', ascending: false)
      .limit(200);

  Future<void> delete(String id) =>
      _client.from('workouts').delete().eq('id', id);

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
    'route': Ewkt.lineString(workout.route),
  };
}
