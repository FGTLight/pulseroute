import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/domain/distance_unit.dart';
import 'package:pulseroute/core/utils/formatters.dart';

void main() {
  test('distance in km and miles', () {
    expect(Formatters.distance(5230, DistanceUnit.km), '5.23 km');
    expect(Formatters.distance(1609.344, DistanceUnit.mi), '1.00 mi');
  });

  test('duration hides hours when not needed', () {
    expect(
      Formatters.duration(const Duration(minutes: 7, seconds: 5)),
      '07:05',
    );
    expect(
      Formatters.duration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });

  test('pace is time per unit, and blank when stopped', () {
    // 1000 m / 312 s = 3.205 m/s → 5:12 per km.
    expect(Formatters.pace(1000 / 312, DistanceUnit.km), '5:12 /km');
    expect(Formatters.pace(0.2, DistanceUnit.km), '--:-- /km');
    // Same speed in miles: 1609.344 / 3.205 ≈ 502 s → 8:22 per mile.
    expect(Formatters.pace(1000 / 312, DistanceUnit.mi), '8:22 /mi');
  });

  test('speed in km/h and mph', () {
    expect(Formatters.speed(5, DistanceUnit.km), '18.0 km/h');
    expect(Formatters.speed(5, DistanceUnit.mi), '11.2 mph');
  });

  test('elevation in meters or feet', () {
    expect(Formatters.elevation(120.4, DistanceUnit.km), '120 m');
    expect(Formatters.elevation(100, DistanceUnit.mi), '328 ft');
  });
}
