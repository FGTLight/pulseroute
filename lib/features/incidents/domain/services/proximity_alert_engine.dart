import 'package:equatable/equatable.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../tracking/domain/entities/track_point.dart';
import '../entities/incident.dart';

/// An incident the user should be warned about.
class ProximityAlert extends Equatable {
  const ProximityAlert({required this.incident, required this.distanceM});

  final Incident incident;

  /// Distance to the incident (to the edge of its area, 0 when inside).
  final double distanceM;

  @override
  List<Object?> get props => [incident, distanceM];
}

/// Decides when an active incident is close enough *and on the user's path*
/// to deserve an alert.
///
/// * Distance is measured to the edge of area incidents (0 when inside).
/// * When the direction of travel is known, only incidents ahead (within
///   [aheadAngleDeg] of the heading) alert; ones behind or to the side do
///   not, unless they are closer than [alwaysAlertM].
/// * Each incident alerts at most once: callers pass the ids already alerted.
///
/// Pure and deterministic, so the rules are fully unit tested.
class ProximityAlertEngine {
  const ProximityAlertEngine({
    this.radiusM = 100,
    this.aheadAngleDeg = 70,
    this.alwaysAlertM = 25,
    this.headingMinDistanceM = 15,
  });

  /// Alert when an incident is closer than this.
  final double radiusM;

  /// Half-width of the cone in front of the user, in degrees.
  final double aheadAngleDeg;

  /// Closer than this, alert regardless of the direction.
  final double alwaysAlertM;

  /// Movement needed to trust the computed heading.
  final double headingMinDistanceM;

  ProximityAlertEngine copyWith({double? radiusM}) => ProximityAlertEngine(
    radiusM: radiusM ?? this.radiusM,
    aheadAngleDeg: aheadAngleDeg,
    alwaysAlertM: alwaysAlertM,
    headingMinDistanceM: headingMinDistanceM,
  );

  /// The closest incident to alert about, or `null`.
  ///
  /// [route] is the recorded route (most recent point last).
  ProximityAlert? check({
    required List<TrackPoint> route,
    required Iterable<Incident> incidents,
    required Set<String> alreadyAlerted,
    required DateTime now,
  }) {
    if (route.isEmpty) return null;
    final position = route.last.point;
    final heading = headingOf(route);

    ProximityAlert? best;
    for (final incident in incidents) {
      if (alreadyAlerted.contains(incident.id) || !incident.isLive(now)) {
        continue;
      }
      final distance = _edgeDistance(position, incident);
      if (distance > radiusM) continue;

      if (heading != null && distance > alwaysAlertM) {
        final toIncident = GeoMath.bearing(position, incident.location);
        if (GeoMath.angleBetween(heading, toIncident) > aheadAngleDeg) {
          continue; // behind or beside the user
        }
      }
      if (best == null || distance < best.distanceM) {
        best = ProximityAlert(incident: incident, distanceM: distance);
      }
    }
    return best;
  }

  /// Direction of travel over the last [headingMinDistanceM] meters of the
  /// current segment, or `null` when the user has not moved enough.
  double? headingOf(List<TrackPoint> route) {
    if (route.length < 2) return null;
    final last = route.last;
    for (var i = route.length - 2; i >= 0; i--) {
      final p = route[i];
      if (p.segment != last.segment) return null;
      if (GeoMath.distance(p.point, last.point) >= headingMinDistanceM) {
        return GeoMath.bearing(p.point, last.point);
      }
    }
    return null;
  }

  static double _edgeDistance(GeoPoint position, Incident incident) {
    final center = GeoMath.distance(position, incident.location);
    final area = incident.radiusM ?? 0;
    return center - area < 0 ? 0 : center - area;
  }
}
