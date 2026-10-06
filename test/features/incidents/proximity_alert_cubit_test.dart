import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident.dart';
import 'package:pulseroute/features/incidents/domain/repositories/alert_notifier.dart';
import 'package:pulseroute/features/incidents/domain/services/proximity_alert_engine.dart';
import 'package:pulseroute/features/incidents/presentation/cubit/proximity_alert_cubit.dart';
import 'package:pulseroute/features/tracking/domain/entities/active_workout.dart';
import 'package:pulseroute/features/tracking/domain/entities/track_point.dart';
import 'package:pulseroute/features/tracking/presentation/bloc/tracking_bloc.dart';

import '../../helpers/incident_builders.dart';
import '../../helpers/mocks.dart';

class _MockNotifier extends Mock implements AlertNotifier;

const _mPerDegLat = 111195.08;

void main() {
  late StreamController<TrackingState> tracking;
  late _MockNotifier notifier;
  late MockSettingsRepository settings;
  late List<Incident> incidents;

  setUpAll(
    () => registerFallbackValue(
      ProximityAlert(incident: incidentAt('x'), distanceM: 0),
    ),
  );

  setUp(() {
    tracking = StreamController<TrackingState>();
    notifier = _MockNotifier();
    settings = MockSettingsRepository();
    when(() => notifier.notify(any())).thenAnswer((_) async {});
    when(() => settings.alertsEnabled).thenReturn(true);
    when(() => settings.alertRadiusM).thenReturn(100);
    // An incident 80 m north of the origin.
    incidents = [incidentAt('pothole', metersNorth: 80)];
  });

  tearDown(() => tracking.close());

  ProximityAlertCubit build() => ProximityAlertCubit(
    tracking: tracking.stream,
    incidents: () => incidents,
    notifier: notifier,
    settings: settings,
    clock: () => incidentNow,
  );

  /// A recording state with the user [metersNorth] of the origin, heading
  /// north, in workout [id].
  TrackingState recordingAt(double metersNorth, {String id = 'w1'}) {
    final points = [
      for (var m = metersNorth - 30; m <= metersNorth + 1e-9; m += 10)
        TrackPoint(
          lat: origin.lat + m / _mPerDegLat,
          lng: origin.lng,
          timestamp: incidentNow.add(Duration(seconds: m.round() + 100)),
          segment: 0,
        ),
    ];
    return TrackingState(
      status: TrackingStatus.recording,
      workout: ActiveWorkout(
        id: id,
        activity: ActivityType.run,
        startedAt: incidentNow,
        status: ActiveWorkoutStatus.recording,
        points: points,
      ),
      position: GeoPoint(points.last.lat, points.last.lng),
    );
  }

  test('alerts once when an incident comes into range ahead', () async {
    final cubit = build();

    tracking.add(recordingAt(-200)); // 280 m away: nothing yet
    await pumpEventQueue();
    verifyNever(() => notifier.notify(any()));

    tracking.add(recordingAt(0)); // 80 m ahead
    await pumpEventQueue();
    expect(cubit.state.latest?.incident.id, 'pothole');
    verify(() => notifier.notify(any())).called(1);

    tracking.add(recordingAt(30)); // still close: no repeat
    await pumpEventQueue();
    verifyNever(() => notifier.notify(any()));
    await cubit.close();
  });

  test('a new workout can alert the same incident again', () async {
    final cubit = build();
    tracking.add(recordingAt(0));
    await pumpEventQueue();

    tracking.add(recordingAt(0, id: 'w2'));
    await pumpEventQueue();

    verify(() => notifier.notify(any())).called(2);
    expect(cubit.state.workoutId, 'w2');
    await cubit.close();
  });

  test('respects the alerts setting and the radius', () async {
    when(() => settings.alertsEnabled).thenReturn(false);
    final cubit = build();
    tracking.add(recordingAt(0));
    await pumpEventQueue();
    verifyNever(() => notifier.notify(any()));

    when(() => settings.alertsEnabled).thenReturn(true);
    when(() => settings.alertRadiusM).thenReturn(50);
    tracking.add(recordingAt(10)); // 70 m away, radius 50 m
    await pumpEventQueue();
    verifyNever(() => notifier.notify(any()));
    await cubit.close();
  });

  test('does nothing while paused and dismiss hides the banner', () async {
    final cubit = build();
    final recording = recordingAt(0);
    tracking.add(
      TrackingState(
        status: TrackingStatus.paused,
        workout: recording.workout!.pause(incidentNow),
      ),
    );
    await pumpEventQueue();
    verifyNever(() => notifier.notify(any()));

    tracking.add(recording);
    await pumpEventQueue();
    expect(cubit.state.latest, isNotNull);

    cubit.dismiss();
    expect(cubit.state.latest, isNull);
    expect(cubit.state.alerted, {'pothole'});
    await cubit.close();
  });
}
