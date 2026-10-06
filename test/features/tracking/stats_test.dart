import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/features/tracking/domain/entities/active_workout.dart';
import 'package:pulseroute/features/tracking/domain/entities/workout_stats.dart';
import 'package:pulseroute/features/tracking/domain/services/stats_accumulator.dart';

import '../../helpers/track_builders.dart';

void main() {
  group('StatsAccumulator', () {
    test('sums the distance of a straight run', () {
      final acc = StatsAccumulator.fromPoints(straightRun(meters: 1000));
      expect(acc.distanceM, closeTo(1000, 0.5));
    });

    test('does not count distance across segments (pauses)', () {
      final points = [
        ...straightRun(meters: 100),
        // Resumed 500 m further away: the gap is not part of the route.
        ...straightRun(
          meters: 100,
          startMeters: 600,
          startSeconds: 300,
          segment: 1,
        ),
      ];
      expect(StatsAccumulator.fromPoints(points).distanceM, closeTo(200, 0.5));
    });

    test('elevation gain ignores noise below the threshold', () {
      final altitudes = <double>[10, 12, 10, 12, 10, 15, 14, 20, 18, 25];
      final points = [
        for (var i = 0; i < altitudes.length; i++)
          pointAt(i * 10, seconds: i * 3, altitude: altitudes[i]),
      ];
      // Counted climbs: 10 → 15 (+5), 15 → 20 (+5), 20 → 25 (+5).
      expect(StatsAccumulator.fromPoints(points).elevationGainM, 15);
    });

    test('current speed uses the last 10 seconds', () {
      final slow = straightRun(meters: 60, speedMps: 2);
      final fast = straightRun(
        meters: 60,
        speedMps: 5,
        startMeters: 60,
        startSeconds: 30,
      ).skip(1);
      final acc = StatsAccumulator.fromPoints([...slow, ...fast]);
      expect(acc.currentSpeedMps, closeTo(5, 0.1));
      expect(acc.maxSpeedMps, closeTo(5, 0.1));
    });

    test('toStats computes average speed and pace from moving time', () {
      final stats = StatsAccumulator.fromPoints(straightRun(meters: 1000))
          .toStats(const Duration(minutes: 5));
      expect(stats.avgSpeedMps, closeTo(1000 / 300, 0.01));
    });

    test('average speed is zero without moving time', () {
      expect(const WorkoutStats(distanceM: 100).avgSpeedMps, 0);
    });
  });

  group('computeSplits', () {
    test('one split per completed kilometer', () {
      // 2.5 km at 4 m/s → each km takes 250 s.
      final splits = computeSplits(straightRun(meters: 2500, speedMps: 4));
      expect(splits, hasLength(2));
      for (final s in splits) {
        expect(s.inMilliseconds, closeTo(250000, 50));
      }
    });

    test('pauses do not count toward a split', () {
      final points = [
        ...straightRun(meters: 500, speedMps: 5), // 100 s
        // 10 minute pause, then the second half of the kilometer.
        ...straightRun(
          meters: 500,
          speedMps: 5,
          startMeters: 500,
          startSeconds: 700,
          segment: 1,
        ),
      ];
      final splits = computeSplits(points);
      expect(splits, hasLength(1));
      expect(splits.single.inSeconds, closeTo(200, 1));
    });

    test('supports miles', () {
      final splits = computeSplits(
        straightRun(meters: 3300),
        unitMeters: 1609.344,
      );
      expect(splits, hasLength(2));
    });
  });

  group('ActiveWorkout clock', () {
    final start = DateTime(2026, 10, 6, 7);
    final workout = ActiveWorkout.start(
      id: 'w1',
      activity: ActivityType.run,
      now: start,
    );

    test('counts only time spent recording', () {
      final paused = workout.pause(start.add(const Duration(minutes: 10)));
      expect(
        paused.elapsed(start.add(const Duration(hours: 1))),
        const Duration(minutes: 10),
      );

      final resumed = paused.resume(start.add(const Duration(minutes: 30)));
      expect(resumed.segment, 1);
      expect(
        resumed.elapsed(start.add(const Duration(minutes: 35))),
        const Duration(minutes: 15),
      );
    });

    test('pausing twice or resuming while recording does nothing', () {
      final now = start.add(const Duration(minutes: 1));
      expect(workout.resume(now), workout);
      final paused = workout.pause(now);
      expect(paused.pause(now.add(const Duration(minutes: 5))), paused);
    });
  });
}
