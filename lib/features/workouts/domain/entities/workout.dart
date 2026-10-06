import 'package:equatable/equatable.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/domain/geo_point.dart';

/// A finished workout.
class Workout extends Equatable {
  const Workout({
    required this.id,
    required this.activity,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.distanceM,
    required this.elevationGainM,
    required this.maxSpeedMps,
    required this.splits,
    required this.route,
    this.synced = false,
  });

  final String id;
  final ActivityType activity;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Moving time (pauses excluded).
  final Duration duration;
  final double distanceM;
  final double elevationGainM;
  final double maxSpeedMps;

  /// Time per completed kilometer.
  final List<Duration> splits;
  final List<GeoPoint> route;

  /// Whether it has been uploaded to the server.
  final bool synced;

  double get avgSpeedMps {
    final seconds = duration.inMilliseconds / 1000;
    return seconds <= 0 ? 0 : distanceM / seconds;
  }

  Workout copyWith({bool? synced}) => Workout(
    id: id,
    activity: activity,
    startedAt: startedAt,
    endedAt: endedAt,
    duration: duration,
    distanceM: distanceM,
    elevationGainM: elevationGainM,
    maxSpeedMps: maxSpeedMps,
    splits: splits,
    route: route,
    synced: synced ?? this.synced,
  );

  @override
  List<Object?> get props => [
    id,
    activity,
    startedAt,
    endedAt,
    duration,
    distanceM,
    elevationGainM,
    maxSpeedMps,
    splits,
    route,
    synced,
  ];
}
