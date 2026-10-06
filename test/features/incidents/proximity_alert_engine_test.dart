import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/core/utils/geo_math.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident.dart';
import 'package:pulseroute/features/incidents/domain/services/proximity_alert_engine.dart';
import 'package:pulseroute/features/tracking/domain/entities/track_point.dart';

import '../../helpers/incident_builders.dart';

const _mPerDegLat = 111195.08;

/// A route heading north from [origin], ending [endMeters] north of it.
List<TrackPoint> northbound({double endMeters = 0, int segment = 0}) => [
  for (var m = endMeters - 40; m <= endMeters + 1e-9; m += 10)
    TrackPoint(
      lat: origin.lat + m / _mPerDegLat,
      lng: origin.lng,
      timestamp: incidentNow.add(Duration(seconds: (m * 0.3).round() + 100)),
      segment: segment,
    ),
];

/// An incident [north] m north and [east] m east of [origin].
Incident at(
  String id, {
  double north = 0,
  double east = 0,
  int? radiusM,
  IncidentStatus status = IncidentStatus.active,
}) {
  final base = incidentAt(id, radiusM: radiusM, status: status);
  const cosLat = 0.8659; // cos(-30°)
  return Incident(
    id: base.id,
    category: base.category,
    severity: base.severity,
    location: GeoPoint(
      origin.lat + north / _mPerDegLat,
      origin.lng + east / (_mPerDegLat * cosLat),
    ),
    radiusM: base.radiusM,
    status: base.status,
    createdAt: base.createdAt,
    expiresAt: base.expiresAt,
  );
}

void main() {
  const engine = ProximityAlertEngine();

  ProximityAlert? check(
    List<Incident> incidents, {
    List<TrackPoint>? route,
    Set<String> alerted = const {},
  }) => engine.check(
    route: route ?? northbound(),
    incidents: incidents,
    alreadyAlerted: alerted,
    now: incidentNow,
  );

  group('GeoMath bearings', () {
    test('north is 0°, east is 90°', () {
      expect(
        GeoMath.bearing(origin, at('n', north: 100).location),
        closeTo(0, 0.5),
      );
      expect(
        GeoMath.bearing(origin, at('e', east: 100).location),
        closeTo(90, 0.5),
      );
    });

    test('angle difference wraps around 360°', () {
      expect(GeoMath.angleBetween(350, 10), 20);
      expect(GeoMath.angleBetween(90, 270), 180);
    });
  });

  test('heading needs at least 15 m of movement in the same segment', () {
    expect(engine.headingOf(northbound()), closeTo(0, 0.5));
    expect(engine.headingOf(northbound().take(1).toList()), isNull);
    // Pauses split segments: a single point after resuming has no heading.
    final resumed = [
      ...northbound(),
      TrackPoint(
        lat: origin.lat + 0.001,
        lng: origin.lng,
        timestamp: incidentNow.add(const Duration(hours: 1)),
        segment: 1,
      ),
    ];
    expect(engine.headingOf(resumed), isNull);
  });

  test('alerts for an incident ahead within the radius', () {
    final alert = check([at('ahead', north: 80)]);
    expect(alert?.incident.id, 'ahead');
    expect(alert!.distanceM, closeTo(80, 1));
  });

  test('ignores incidents beyond the radius', () {
    expect(check([at('far', north: 150)]), isNull);
  });

  test('ignores incidents behind or beside the path', () {
    expect(check([at('behind', north: -60)]), isNull);
    expect(check([at('beside', east: 70)]), isNull);
  });

  test('very close incidents alert whatever the direction', () {
    expect(check([at('next-to-me', east: 20)])?.incident.id, 'next-to-me');
  });

  test('without a heading (just started) any nearby incident alerts', () {
    final standing = northbound().take(1).toList();
    expect(
      check([at('behind', north: -40)], route: standing)?.incident.id,
      'behind',
    );
  });

  test('area incidents count from their edge, and inside always alerts', () {
    // Center 250 m away but the dark area has a 200 m radius → 50 m.
    final alert = check([at('dark', north: 250, radiusM: 200)]);
    expect(alert!.distanceM, closeTo(50, 1));

    // Inside an area behind the user: still alerts (distance 0).
    final inside = check([at('inside', north: -30, radiusM: 100)]);
    expect(inside!.distanceM, 0);
  });

  test('never repeats an incident and picks the closest new one', () {
    final incidents = [at('a', north: 40), at('b', north: 90)];
    expect(check(incidents)?.incident.id, 'a');
    expect(check(incidents, alerted: {'a'})?.incident.id, 'b');
    expect(check(incidents, alerted: {'a', 'b'}), isNull);
  });

  test('resolved incidents do not alert', () {
    expect(
      check([at('done', north: 50, status: IncidentStatus.resolved)]),
      isNull,
    );
  });

  test('the radius is configurable', () {
    final wide = engine.copyWith(radiusM: 200);
    expect(
      wide.check(
        route: northbound(),
        incidents: [at('far', north: 150)],
        alreadyAlerted: const {},
        now: incidentNow,
      ),
      isNotNull,
    );
  });
}
