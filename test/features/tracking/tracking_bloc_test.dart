import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/core/utils/time.dart';
import 'package:pulseroute/features/tracking/domain/entities/active_workout.dart';
import 'package:pulseroute/features/tracking/domain/entities/track_point.dart';
import 'package:pulseroute/features/tracking/domain/entities/workout_stats.dart';
import 'package:pulseroute/features/tracking/domain/repositories/location_repository.dart';
import 'package:pulseroute/features/tracking/domain/repositories/workout_recorder_repository.dart';
import 'package:pulseroute/features/tracking/domain/usecases/finish_workout.dart';
import 'package:pulseroute/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:pulseroute/features/workouts/domain/entities/workout.dart';
import 'package:pulseroute/features/workouts/domain/repositories/workout_sync_repository.dart';

import '../../helpers/track_builders.dart';

class _MockLocation extends Mock implements LocationRepository;

class _MockRecorder extends Mock implements WorkoutRecorderRepository;

class _MockSync extends Mock implements WorkoutSyncRepository;

/// Ticker driven by the test.
class _ManualTicker implements Ticker {
  final controller = StreamController<void>.broadcast();

  @override
  Stream<void> tick(Duration interval) => controller.stream;
}

void main() {
  late _MockLocation location;
  late _MockRecorder recorder;
  late _MockSync sync;
  late StreamController<LocationFix> fixes;
  late _ManualTicker ticker;
  late DateTime now;

  setUpAll(() {
    registerFallbackValue(ActivityType.run);
    registerFallbackValue(
      ActiveWorkout.start(id: 'x', activity: ActivityType.run, now: t0),
    );
    registerFallbackValue(pointAt(0, seconds: 0));
    registerFallbackValue(const WorkoutStats());
  });

  setUp(() {
    location = _MockLocation();
    recorder = _MockRecorder();
    sync = _MockSync();
    fixes = StreamController<LocationFix>.broadcast();
    ticker = _ManualTicker();
    now = t0;

    when(() => location.requestAccess())
        .thenAnswer((_) async => LocationAccess.whileInUse);
    when(() => location.checkAccess())
        .thenAnswer((_) async => LocationAccess.whileInUse);
    when(() => location.watch(any())).thenAnswer((_) => fixes.stream);
    when(() => recorder.saveState(any()))
        .thenAnswer((_) async => const Success(null));
    when(() => recorder.appendPoint(any(), any()))
        .thenAnswer((_) async => const Success(null));
    when(() => recorder.discard(any()))
        .thenAnswer((_) async => const Success(null));
    when(() => recorder.loadActive())
        .thenAnswer((_) async => const Success(null));
    when(() => sync.syncPending()).thenAnswer((_) async => const Success(0));
    when(() => location.isBatteryOptimized()).thenAnswer((_) async => false);
    when(() => location.requestBatteryExemption()).thenAnswer((_) async {});
    when(() => location.openAppSettings()).thenAnswer((_) async {});
    when(() => location.openLocationSettings()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await fixes.close();
    await ticker.controller.close();
  });

  TrackingBloc build() => TrackingBloc(
    location: location,
    recorder: recorder,
    finishWorkout: FinishWorkout(recorder: recorder, sync: sync),
    newId: () => 'w1',
    clock: () => now,
    ticker: ticker,
  );

  /// Starts recording and waits until the bloc is listening.
  Future<void> start(TrackingBloc bloc) async {
    bloc.add(const TrackingStartRequested());
    await pumpEventQueue();
  }

  group('start', () {
    blocTest<TrackingBloc, TrackingState>(
      'records with the selected activity once location is granted',
      build: build,
      act: (bloc) async {
        bloc.add(const TrackingActivitySelected(ActivityType.bike));
        await start(bloc);
      },
      expect: () => [
        isA<TrackingState>().having(
          (s) => s.activity,
          'activity',
          ActivityType.bike,
        ),
        isA<TrackingState>().having(
          (s) => s.status,
          'status',
          TrackingStatus.starting,
        ),
        isA<TrackingState>()
            .having((s) => s.status, 'status', TrackingStatus.recording)
            .having((s) => s.workout?.activity, 'activity', ActivityType.bike),
      ],
      verify: (_) {
        verify(() => recorder.saveState(any())).called(1);
        verify(() => location.watch(ActivityType.bike)).called(1);
      },
    );

    test('explains why before asking, then asks once accepted', () async {
      when(() => location.checkAccess())
          .thenAnswer((_) async => LocationAccess.denied);
      final bloc = build();

      await start(bloc);
      expect(bloc.state.showRationale, isTrue);
      expect(bloc.state.status, TrackingStatus.idle);
      verifyNever(() => location.requestAccess());

      bloc.add(const TrackingRationaleAccepted());
      await pumpEventQueue();
      expect(bloc.state.status, TrackingStatus.recording);
      verify(() => location.requestAccess()).called(1);
      await bloc.close();
    });

    test('a permanent denial points to the settings instead', () async {
      when(() => location.checkAccess())
          .thenAnswer((_) async => LocationAccess.deniedForever);
      final bloc = build();

      await start(bloc);
      expect(bloc.state.showRationale, isFalse);
      expect(bloc.state.accessIssue, LocationAccess.deniedForever);

      bloc.add(const TrackingSettingsRequested());
      await pumpEventQueue();
      verify(() => location.openAppSettings()).called(1);
      verifyNever(() => location.watch(any()));
      await bloc.close();
    });

    test('shows the battery tip when Android may kill tracking', () async {
      when(() => location.isBatteryOptimized()).thenAnswer((_) async => true);
      final bloc = build()..add(const TrackingRecoveryRequested());
      await pumpEventQueue();
      expect(bloc.state.showBatteryTip, isTrue);

      when(() => location.isBatteryOptimized()).thenAnswer((_) async => false);
      bloc.add(const TrackingBatteryExemptionRequested());
      await pumpEventQueue();
      expect(bloc.state.showBatteryTip, isFalse);
      verify(() => location.requestBatteryExemption()).called(1);
      await bloc.close();
    });
  });

  group('recording', () {
    test(
      'accepted fixes update the route and stats and are persisted',
      () async {
        final bloc = build();
        await start(bloc);

        for (final p in straightRun(meters: 100)) {
          fixes.add(
            fixAt(
              (p.lat + 30) * metersPerDegreeLat,
              seconds: p.timestamp.difference(t0).inMilliseconds / 1000,
            ),
          );
        }
        await pumpEventQueue();

        expect(bloc.state.workout!.points, hasLength(11));
        // Smoothing trails the newest fix by about one sample (10 m)...
        expect(bloc.state.stats.distanceM, closeTo(90, 1));
        verify(() => recorder.appendPoint('w1', any())).called(11);

        // ...and pausing flushes it, so the full distance is counted.
        bloc.add(const TrackingPauseRequested());
        await pumpEventQueue();
        expect(bloc.state.stats.distanceM, closeTo(100, 0.5));
        verify(() => recorder.appendPoint('w1', any())).called(1);
        await bloc.close();
      },
    );

    test('low accuracy fixes are flagged but not recorded', () async {
      final bloc = build();
      await start(bloc);

      fixes.add(fixAt(0, seconds: 0, accuracy: 80));
      await pumpEventQueue();

      expect(bloc.state.gpsWeak, isTrue);
      expect(bloc.state.workout!.points, isEmpty);
      verifyNever(() => recorder.appendPoint(any(), any()));
      await bloc.close();
    });

    test('the ticker refreshes the moving time', () async {
      final bloc = build();
      await start(bloc);

      now = t0.add(const Duration(seconds: 42));
      ticker.controller.add(null);
      await pumpEventQueue();

      expect(bloc.state.stats.duration, const Duration(seconds: 42));
      await bloc.close();
    });

    test(
      'pause stops GPS and the clock; resume starts a new segment',
      () async {
        final bloc = build();
        await start(bloc);

        now = t0.add(const Duration(minutes: 5));
        bloc.add(const TrackingPauseRequested());
        await pumpEventQueue();
        expect(bloc.state.status, TrackingStatus.paused);
        expect(fixes.hasListener, isFalse);

        now = t0.add(const Duration(minutes: 20));
        bloc.add(const TrackingResumeRequested());
        await pumpEventQueue();
        expect(bloc.state.status, TrackingStatus.recording);
        expect(bloc.state.workout!.segment, 1);
        expect(bloc.state.stats.duration, const Duration(minutes: 5));
        await bloc.close();
      },
    );

    test('losing the location stream pauses the workout', () async {
      final bloc = build();
      await start(bloc);

      // The user turns the GPS off while recording.
      when(() => location.checkAccess())
          .thenAnswer((_) async => LocationAccess.serviceDisabled);
      fixes.addError(Exception('GPS off'));
      await pumpEventQueue();

      expect(bloc.state.status, TrackingStatus.paused);
      expect(bloc.state.accessIssue, LocationAccess.serviceDisabled);
      await bloc.close();
    });
  });

  group('finish', () {
    test('saves the workout and shows the summary', () async {
      final finished = Workout(
        id: 'w1',
        activity: ActivityType.run,
        startedAt: t0,
        endedAt: t0.add(const Duration(minutes: 30)),
        duration: const Duration(minutes: 30),
        distanceM: 5000,
        elevationGainM: 20,
        maxSpeedMps: 4,
        splits: const [],
        route: const [],
      );
      when(
        () => recorder.finish(
          any(),
          stats: any(named: 'stats'),
          splits: any(named: 'splits'),
          endedAt: any(named: 'endedAt'),
        ),
      ).thenAnswer((_) async => Success(finished));

      final bloc = build();
      await start(bloc);
      bloc.add(const TrackingStopRequested());
      await pumpEventQueue();

      expect(bloc.state.status, TrackingStatus.finished);
      expect(bloc.state.finishedWorkout, finished);
      expect(fixes.hasListener, isFalse);
      verify(() => sync.syncPending()).called(1);
      await bloc.close();
    });

    test('keeps the workout if saving fails', () async {
      when(
        () => recorder.finish(
          any(),
          stats: any(named: 'stats'),
          splits: any(named: 'splits'),
          endedAt: any(named: 'endedAt'),
        ),
      ).thenAnswer((_) async => const Err(CacheFailure('Disk full')));

      final bloc = build();
      await start(bloc);
      bloc.add(const TrackingStopRequested());
      await pumpEventQueue();

      expect(bloc.state.status, TrackingStatus.paused);
      expect(bloc.state.workout, isNotNull);
      expect(bloc.state.errorMessage, 'Disk full');
      await bloc.close();
    });

    test('discard deletes the workout', () async {
      final bloc = build();
      await start(bloc);
      bloc.add(const TrackingDiscardRequested());
      await pumpEventQueue();

      expect(bloc.state.status, TrackingStatus.idle);
      expect(bloc.state.workout, isNull);
      verify(() => recorder.discard('w1')).called(1);
      await bloc.close();
    });
  });

  group('recovery', () {
    final interrupted = ActiveWorkout(
      id: 'w9',
      activity: ActivityType.run,
      startedAt: t0,
      status: ActiveWorkoutStatus.recording,
      resumedAt: t0,
      points: straightRun(meters: 200),
    );

    test('resumes a workout that was recording when the app died', () async {
      when(() => recorder.loadActive())
          .thenAnswer((_) async => Success(interrupted));
      now = t0.add(const Duration(minutes: 3));

      final bloc = build()..add(const TrackingRecoveryRequested());
      await pumpEventQueue();

      expect(bloc.state.status, TrackingStatus.recording);
      expect(bloc.state.workout!.segment, 1); // no line across the gap
      expect(bloc.state.stats.distanceM, closeTo(200, 1));
      expect(bloc.state.stats.duration, const Duration(minutes: 3));
      expect(fixes.hasListener, isTrue);
      await bloc.close();
    });

    test('recovers as paused when location is no longer allowed', () async {
      when(() => recorder.loadActive())
          .thenAnswer((_) async => Success(interrupted));
      when(() => location.checkAccess())
          .thenAnswer((_) async => LocationAccess.denied);

      final bloc = build()..add(const TrackingRecoveryRequested());
      await pumpEventQueue();

      expect(bloc.state.status, TrackingStatus.paused);
      expect(bloc.state.accessIssue, LocationAccess.denied);
      await bloc.close();
    });
  });
}
