import 'package:equatable/equatable.dart';

import '../../../../core/utils/geo_math.dart';
import '../entities/track_point.dart';
import '../entities/workout_stats.dart';

/// Incrementally computes distance, elevation gain and speeds as points
/// arrive, so a long workout does not recompute everything every second.
///
/// Immutable: [add] returns a new accumulator.
class StatsAccumulator extends Equatable {
  const StatsAccumulator({
    this.distanceM = 0,
    this.elevationGainM = 0,
    this.maxSpeedMps = 0,
    this.elevationRef,
    this.recent = const [],
  });

  /// Rebuilds the accumulator from stored points (e.g. after a restart).
  factory StatsAccumulator.fromPoints(Iterable<TrackPoint> points) =>
      points.fold(const StatsAccumulator(), (acc, p) => acc.add(p));

  /// Altitude changes smaller than this are treated as GPS noise.
  static const elevationThresholdM = 3.0;

  /// Time window used for the current speed.
  static const currentSpeedWindow = Duration(seconds: 10);

  final double distanceM;
  final double elevationGainM;
  final double maxSpeedMps;

  /// Altitude of the last counted elevation change (hysteresis reference).
  final double? elevationRef;

  /// Points of the current segment inside [currentSpeedWindow].
  final List<TrackPoint> recent;

  TrackPoint? get last => recent.isEmpty ? null : recent.last;

  StatsAccumulator add(TrackPoint point) {
    final previous = last;
    final sameSegment = previous != null && previous.segment == point.segment;

    var distance = distanceM;
    var maxSpeed = maxSpeedMps;
    if (sameSegment) {
      final step = GeoMath.distance(previous.point, point.point);
      distance += step;
      final seconds =
          point.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
      if (seconds > 0) {
        final speed = point.speedMps ?? step / seconds;
        if (speed > maxSpeed) maxSpeed = speed;
      }
    }

    // Elevation gain with hysteresis: only count climbs once the altitude
    // moved more than the threshold away from the reference.
    var gain = elevationGainM;
    var ref = elevationRef;
    final altitude = point.altitudeM;
    if (altitude != null) {
      if (ref == null) {
        ref = altitude;
      } else if (altitude - ref >= elevationThresholdM) {
        gain += altitude - ref;
        ref = altitude;
      } else if (ref - altitude >= elevationThresholdM) {
        ref = altitude;
      }
    }

    final cutoff = point.timestamp.subtract(currentSpeedWindow);
    final window = [
      if (sameSegment) ...recent.where((p) => !p.timestamp.isBefore(cutoff)),
      point,
    ];

    return StatsAccumulator(
      distanceM: distance,
      elevationGainM: gain,
      maxSpeedMps: maxSpeed,
      elevationRef: ref,
      recent: window,
    );
  }

  /// Speed over the recent window, or 0 when not moving.
  double get currentSpeedMps {
    if (recent.length < 2) return 0;
    var meters = 0.0;
    for (var i = 1; i < recent.length; i++) {
      meters += GeoMath.distance(recent[i - 1].point, recent[i].point);
    }
    final seconds =
        recent.last.timestamp
            .difference(recent.first.timestamp)
            .inMilliseconds /
        1000;
    return seconds <= 0 ? 0 : meters / seconds;
  }

  /// Snapshot for the UI, given the moving time from the workout clock.
  WorkoutStats toStats(Duration duration) => WorkoutStats(
    distanceM: distanceM,
    duration: duration,
    elevationGainM: elevationGainM,
    currentSpeedMps: currentSpeedMps,
    maxSpeedMps: maxSpeedMps,
  );

  @override
  List<Object?> get props => [
    distanceM,
    elevationGainM,
    maxSpeedMps,
    elevationRef,
    recent,
  ];
}

/// Time taken for each completed kilometer (or mile, with [unitMeters]).
///
/// Only time between consecutive points of the same segment counts, so
/// pauses are excluded. The crossing time of each boundary is interpolated
/// between the two points around it.
List<Duration> computeSplits(
  List<TrackPoint> points, {
  double unitMeters = 1000,
}) {
  final splits = <Duration>[];
  var distance = 0.0;
  var movingMs = 0.0;
  var splitStartMs = 0.0;

  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    if (a.segment != b.segment) continue;

    final step = GeoMath.distance(a.point, b.point);
    final stepMs = b.timestamp
        .difference(a.timestamp)
        .inMilliseconds
        .toDouble();
    // A zero-time step (e.g. the point added by GpsNoiseFilter.flush) still
    // adds distance.
    if (step <= 0 || stepMs < 0) continue;

    var consumed = 0.0;
    while (distance + (step - consumed) >= unitMeters * (splits.length + 1)) {
      final toBoundary = unitMeters * (splits.length + 1) - distance;
      final crossingMs = movingMs + stepMs * ((consumed + toBoundary) / step);
      splits.add(Duration(milliseconds: (crossingMs - splitStartMs).round()));
      splitStartMs = crossingMs;
      distance += toBoundary;
      consumed += toBoundary;
    }
    distance += step - consumed;
    movingMs += stepMs;
  }
  return splits;
}
