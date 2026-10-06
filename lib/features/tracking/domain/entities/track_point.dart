import 'package:equatable/equatable.dart';

import '../../../../core/domain/geo_point.dart';

/// A raw reading from the GPS, before any filtering.
class LocationFix extends Equatable {
  const LocationFix({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.timestamp,
    this.altitudeM,
    this.speedMps,
  });

  final double lat;
  final double lng;

  /// Horizontal accuracy radius (68% confidence), in meters.
  final double accuracyM;
  final DateTime timestamp;
  final double? altitudeM;

  /// Speed reported by the GPS chip, if available.
  final double? speedMps;

  GeoPoint get point => GeoPoint(lat, lng);

  @override
  List<Object?> get props => [lat, lng, accuracyM, timestamp, altitudeM];
}

/// A filtered point that is part of the recorded route.
///
/// [segment] increases every time the workout is resumed after a pause:
/// distance is never counted across two segments.
class TrackPoint extends Equatable {
  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.segment,
    this.accuracyM = 0,
    this.altitudeM,
    this.speedMps,
  });

  final double lat;
  final double lng;
  final DateTime timestamp;
  final int segment;
  final double accuracyM;
  final double? altitudeM;
  final double? speedMps;

  GeoPoint get point => GeoPoint(lat, lng);

  @override
  List<Object?> get props => [lat, lng, timestamp, segment, altitudeM];
}
