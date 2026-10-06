import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/core/utils/geo_math.dart';

void main() {
  test('one degree of latitude is ~111.2 km', () {
    expect(
      GeoMath.distance(const GeoPoint(0, 0), const GeoPoint(1, 0)),
      closeTo(111195, 1),
    );
  });

  test('known city distance: Porto Alegre to São Paulo (~852 km)', () {
    const portoAlegre = GeoPoint(-30.0346, -51.2177);
    const saoPaulo = GeoPoint(-23.5505, -46.6333);
    expect(GeoMath.distance(portoAlegre, saoPaulo) / 1000, closeTo(852, 5));
  });

  test('distance is symmetric and zero for the same point', () {
    const a = GeoPoint(-30.03, -51.22);
    const b = GeoPoint(-30.04, -51.21);
    expect(GeoMath.distance(a, b), closeTo(GeoMath.distance(b, a), 1e-6));
    expect(GeoMath.distance(a, a), 0);
  });

  test('distance to a segment uses the closest point on it', () {
    const a = GeoPoint(0, 0);
    const b = GeoPoint(0, 0.01); // ~1.1 km east
    // 0.0005° north of the middle of the segment: ~55.6 m away.
    const p = GeoPoint(0.0005, 0.005);
    expect(GeoMath.distanceToSegment(p, a, b), closeTo(55.6, 0.5));
    // Beyond the end: distance to the endpoint.
    const beyond = GeoPoint(0, 0.011);
    expect(
      GeoMath.distanceToSegment(beyond, a, b),
      closeTo(GeoMath.distance(beyond, b), 0.5),
    );
  });
}
