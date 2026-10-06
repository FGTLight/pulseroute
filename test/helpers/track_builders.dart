import 'package:pulseroute/features/tracking/domain/entities/track_point.dart';

/// Meters per degree of latitude on the sphere used by `GeoMath`.
const metersPerDegreeLat = 111195.08;

final t0 = DateTime(2026, 10, 6, 7);

/// A fix [metersNorth] north of a fixed origin, [seconds] after [t0].
LocationFix fixAt(
  double metersNorth, {
  required double seconds,
  double accuracy = 5,
  double? altitude,
}) => LocationFix(
  lat: -30.0 + metersNorth / metersPerDegreeLat,
  lng: -51.2,
  accuracyM: accuracy,
  timestamp: t0.add(Duration(milliseconds: (seconds * 1000).round())),
  altitudeM: altitude,
);

/// A track point [metersNorth] north of the origin.
TrackPoint pointAt(
  double metersNorth, {
  required double seconds,
  int segment = 0,
  double? altitude,
}) => TrackPoint(
  lat: -30.0 + metersNorth / metersPerDegreeLat,
  lng: -51.2,
  timestamp: t0.add(Duration(milliseconds: (seconds * 1000).round())),
  segment: segment,
  altitudeM: altitude,
);

/// Points every [step] meters at constant [speedMps] over [meters].
List<TrackPoint> straightRun({
  required double meters,
  double step = 10,
  double speedMps = 3,
  double startSeconds = 0,
  double startMeters = 0,
  int segment = 0,
}) => [
  for (var d = 0.0; d <= meters + 1e-9; d += step)
    pointAt(
      startMeters + d,
      seconds: startSeconds + d / speedMps,
      segment: segment,
    ),
];
