import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/features/tracking/domain/services/gps_noise_filter.dart';

import '../../helpers/track_builders.dart';

void main() {
  late GpsNoiseFilter filter;

  setUp(() => filter = GpsNoiseFilter(activity: ActivityType.run));

  RejectionReason? reasonOf(FilterResult r) => r is Rejected ? r.reason : null;

  test('accepts the first accurate fix', () {
    final result = filter.process(fixAt(0, seconds: 0), segment: 0);
    expect(result, isA<Accepted>());
    expect((result as Accepted).point.segment, 0);
  });

  test('drops fixes with low accuracy', () {
    final result = filter.process(
      fixAt(0, seconds: 0, accuracy: 60),
      segment: 0,
    );
    expect(reasonOf(result), RejectionReason.lowAccuracy);
  });

  test('drops impossible jumps for the activity', () {
    filter.process(fixAt(0, seconds: 0), segment: 0);
    // 200 m in 2 s = 100 m/s: impossible on foot.
    final jump = filter.process(fixAt(200, seconds: 2), segment: 0);
    expect(reasonOf(jump), RejectionReason.impossibleJump);
  });

  test('the same jump is fine on a bike at realistic speed', () {
    final bike = GpsNoiseFilter(activity: ActivityType.bike)
      ..process(fixAt(0, seconds: 0), segment: 0);
    // 40 m in 2 s = 20 m/s (72 km/h): too fast to run, possible downhill.
    expect(
      GpsNoiseFilter(activity: ActivityType.run)
          .process(fixAt(0, seconds: 0), segment: 0),
      isA<Accepted>(),
    );
    expect(bike.process(fixAt(40, seconds: 2), segment: 0), isA<Accepted>());
  });

  test('drops jitter while standing still', () {
    filter.process(fixAt(0, seconds: 0), segment: 0);
    final jitter = filter.process(fixAt(1, seconds: 2), segment: 0);
    expect(reasonOf(jitter), RejectionReason.tooClose);
  });

  test('drops fixes that are not newer than the last point', () {
    filter.process(fixAt(0, seconds: 5), segment: 0);
    expect(
      reasonOf(filter.process(fixAt(20, seconds: 5), segment: 0)),
      RejectionReason.outOfOrder,
    );
  });

  test('smoothing weights fixes by accuracy', () {
    filter
      ..process(fixAt(0, seconds: 0), segment: 0)
      ..process(fixAt(10, seconds: 3), segment: 0)
      ..process(fixAt(20, seconds: 6), segment: 0);
    // A noisy fix (24 m accuracy) 20 m ahead barely moves the route.
    final result = filter.process(
      fixAt(40, seconds: 9, accuracy: 24),
      segment: 0,
    ) as Accepted;
    final metersNorth = (result.point.lat + 30) * metersPerDegreeLat;
    expect(metersNorth, closeTo(15.5, 0.5));
  });

  test('flush appends the last real fix the smoothed route trails', () {
    for (var i = 0; i <= 10; i++) {
      filter.process(fixAt(i * 10, seconds: i * 3.0), segment: 0);
    }
    final flushed = filter.flush(segment: 0)!;
    expect((flushed.lat + 30) * metersPerDegreeLat, closeTo(100, 0.01));
    // Nothing left to flush afterwards.
    expect(filter.flush(segment: 0), isNull);
  });

  test('reset forgets the previous point (new segment)', () {
    filter
      ..process(fixAt(0, seconds: 0), segment: 0)
      ..reset();
    // Far away after a pause: not an impossible jump anymore.
    expect(
      filter.process(fixAt(500, seconds: 10), segment: 1),
      isA<Accepted>(),
    );
  });
}
