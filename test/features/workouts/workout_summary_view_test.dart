import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/core/domain/distance_unit.dart';
import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/features/workouts/domain/entities/workout.dart';
import 'package:pulseroute/features/workouts/presentation/widgets/workout_summary_view.dart';

void main() {
  final start = DateTime(2026, 10, 6, 7, 30);

  Workout workout({
    ActivityType activity = ActivityType.run,
    bool synced = true,
  }) => Workout(
    id: 'w1',
    activity: activity,
    startedAt: start,
    endedAt: start.add(const Duration(minutes: 27)),
    duration: const Duration(minutes: 26),
    distanceM: 5000,
    elevationGainM: 42,
    maxSpeedMps: 4.2,
    splits: const [
      Duration(minutes: 5, seconds: 20),
      Duration(minutes: 5, seconds: 5),
      Duration(minutes: 5, seconds: 15),
      Duration(minutes: 5, seconds: 10),
      Duration(minutes: 5, seconds: 10),
    ],
    route: const [GeoPoint(-30.03, -51.24), GeoPoint(-30.04, -51.24)],
    synced: synced,
  );

  Future<void> pump(
    WidgetTester tester,
    Workout w, {
    DistanceUnit unit = DistanceUnit.km,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WorkoutSummaryView(
          workout: w,
          unit: unit,
          // The native map is replaced with a placeholder in tests.
          mapBuilder: (route) => Text('map with ${route.length} points'),
        ),
      ),
    ),
  );

  testWidgets('shows the key numbers of a run with pace', (tester) async {
    await pump(tester, workout());

    expect(find.text('5.00 km'), findsOneWidget);
    expect(find.text('26:00'), findsOneWidget);
    // 5 km in 26 min → 5:12 per km.
    expect(find.text('5:12 /km'), findsOneWidget);
    expect(find.text('42 m'), findsOneWidget);
    expect(find.text('map with 2 points'), findsOneWidget);
    expect(find.text('Avg pace'), findsOneWidget);
  });

  testWidgets('rides show speed instead of pace', (tester) async {
    await pump(tester, workout(activity: ActivityType.bike));

    expect(find.text('Avg speed'), findsOneWidget);
    expect(find.text('Avg pace'), findsNothing);
  });

  testWidgets('lists one split per km and flags unsynced workouts', (
    tester,
  ) async {
    await pump(tester, workout(synced: false));
    await tester.scrollUntilVisible(find.text('5'), 100);

    expect(find.text('Splits per km'), findsOneWidget);
    expect(find.text('05:05'), findsOneWidget); // fastest split
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('uses miles when selected', (tester) async {
    await pump(tester, workout(), unit: DistanceUnit.mi);

    expect(find.text('3.11 mi'), findsOneWidget);
  });
}
