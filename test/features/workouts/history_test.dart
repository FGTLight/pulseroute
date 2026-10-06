import 'dart:async';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/database/app_database.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/features/incidents/domain/repositories/incident_repository.dart';
import 'package:pulseroute/features/tracking/data/repositories/drift_workout_recorder_repository.dart';
import 'package:pulseroute/features/tracking/domain/entities/active_workout.dart';
import 'package:pulseroute/features/tracking/domain/entities/track_point.dart';
import 'package:pulseroute/features/tracking/domain/entities/workout_stats.dart';
import 'package:pulseroute/features/workouts/data/datasources/workout_remote_data_source.dart';
import 'package:pulseroute/features/workouts/data/repositories/drift_workout_repository.dart';
import 'package:pulseroute/features/workouts/domain/entities/workout.dart';
import 'package:pulseroute/features/workouts/domain/entities/workout_preview.dart';
import 'package:pulseroute/features/workouts/domain/repositories/workout_repository.dart';
import 'package:pulseroute/features/workouts/domain/repositories/workout_sync_repository.dart';
import 'package:pulseroute/features/workouts/domain/services/route_simplifier.dart';
import 'package:pulseroute/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:pulseroute/features/workouts/presentation/cubit/history_cubit.dart';
import 'package:pulseroute/features/workouts/presentation/cubit/workout_detail_cubit.dart';

import '../../helpers/incident_builders.dart';
import '../../helpers/track_builders.dart';

class _MockRemote extends Mock implements WorkoutRemoteDataSource;

class _MockWorkouts extends Mock implements WorkoutRepository;

class _MockSync extends Mock implements WorkoutSyncRepository;

class _MockIncidents extends Mock implements IncidentRepository;

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('simplifyRoute keeps the ends and limits the points', () {
    final route = [for (var i = 0; i < 1000; i++) GeoPoint(i * 1e-5, 0)];
    final simple = simplifyRoute(route, maxPoints: 50);
    expect(simple, hasLength(50));
    expect(simple.first, route.first);
    expect(simple.last, route.last);
    expect(simplifyRoute(route.take(10).toList()), hasLength(10));
  });

  group('DriftWorkoutRepository', () {
    late AppDatabase db;
    late _MockRemote remote;
    late DriftWorkoutRepository repository;
    late DriftWorkoutRecorderRepository recorder;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      remote = _MockRemote();
      when(() => remote.isSignedIn).thenReturn(true);
      repository = DriftWorkoutRepository(db, remote);
      recorder = DriftWorkoutRecorderRepository(db);
    });

    tearDown(() => db.close());

    Future<void> record(String id, {double meters = 500, DateTime? at}) async {
      final w = ActiveWorkout.start(
        id: id,
        activity: ActivityType.run,
        now: at ?? t0,
      );
      await recorder.saveState(w);
      final points = straightRun(meters: meters);
      for (final p in points) {
        await recorder.appendPoint(id, p);
      }
      await recorder.finish(
        w.withPoints(points),
        stats: WorkoutStats(
          distanceM: meters,
          duration: const Duration(minutes: 3),
        ),
        splits: const [],
        endedAt: (at ?? t0).add(const Duration(minutes: 3)),
      );
    }

    test(
      'history lists finished workouts, newest first, with previews',
      () async {
        await record('old', at: t0);
        await record('new', meters: 2000, at: t0.add(const Duration(days: 1)));
        // An unfinished workout is not part of the history.
        await recorder.saveState(
          ActiveWorkout.start(id: 'live', activity: ActivityType.run, now: t0),
        );

        final history = await repository.watchHistory().first;
        expect(history.map((w) => w.id), ['new', 'old']);
        // 201 recorded points are reduced to a 60-point preview.
        expect(history.first.preview, hasLength(60));
        expect(history.first.distanceM, 2000);
      },
    );

    test('getWorkout returns the full route', () async {
      await record('w1');
      final workout = (await repository.getWorkout('w1')).valueOrNull!;
      expect(workout.route, hasLength(51));
      expect(
        (await repository.getWorkout('missing')).failureOrNull,
        isA<NotFoundFailure>(),
      );
    });

    test('imports server workouts once, with their route', () async {
      when(remote.fetchAll).thenAnswer(
        (_) async => [
          {
            'id': 'from-web',
            'activity': 'bike',
            'started_at': '2026-10-01T07:00:00Z',
            'ended_at': '2026-10-01T08:00:00Z',
            'duration_s': 3300,
            'distance_m': 24000.0,
            'elevation_gain_m': 120.0,
            'max_speed_mps': 12.5,
            'splits_s': [140, 150],
            'route_points': [
              [-30.03, -51.24],
              [-30.04, -51.23],
              [-30.05, -51.22],
            ],
          },
        ],
      );

      expect((await repository.refreshFromServer()).valueOrNull, 1);
      expect((await repository.refreshFromServer()).valueOrNull, 0);

      final workout = (await repository.getWorkout('from-web')).valueOrNull!;
      expect(workout.activity, ActivityType.bike);
      expect(workout.synced, isTrue);
      expect(workout.route, hasLength(3));
      expect(workout.splits.first, const Duration(seconds: 140));
      expect(workout.duration, const Duration(seconds: 3300));
    });

    test('deleting removes it locally and, if uploaded, remotely', () async {
      when(() => remote.delete(any())).thenAnswer((_) async {});
      await record('local-only');
      await record('uploaded');
      await (db.update(db.localWorkouts)..where((w) => w.id.equals('uploaded')))
          .write(const LocalWorkoutsCompanion(synced: Value(true)));

      await repository.delete('local-only');
      await repository.delete('uploaded');

      verify(() => remote.delete('uploaded')).called(1);
      verifyNever(() => remote.delete('local-only'));
      expect(await repository.watchHistory().first, isEmpty);
      expect(await db.select(db.localTrackPoints).get(), isEmpty);
    });

    test('clearAll wipes the device data (account deletion)', () async {
      await record('w1');
      await db.clearAll();
      expect(await repository.watchHistory().first, isEmpty);
    });
  });

  group('HistoryCubit', () {
    late _MockWorkouts workouts;
    late _MockSync sync;
    late StreamController<List<WorkoutPreview>> history;

    setUp(() {
      workouts = _MockWorkouts();
      sync = _MockSync();
      history = StreamController<List<WorkoutPreview>>();
      when(workouts.watchHistory).thenAnswer((_) => history.stream);
    });

    tearDown(() => history.close());

    HistoryCubit build(DateTime now) => HistoryCubit(
      watchHistory: WatchHistory(workouts),
      refreshHistory: RefreshHistory(workouts, sync),
      deleteWorkout: DeleteWorkout(workouts),
      clock: () => now,
    );

    WorkoutPreview preview(String id, DateTime at, double meters) =>
        WorkoutPreview(
          id: id,
          activity: ActivityType.run,
          startedAt: at,
          duration: const Duration(minutes: 30),
          distanceM: meters,
          preview: const [],
        );

    test('weekly totals only count workouts since Monday', () async {
      // Tuesday 6 Oct 2026; Monday was the 5th.
      final cubit = build(DateTime(2026, 10, 6, 20));
      history.add([
        preview('tue', DateTime(2026, 10, 6, 7), 5000),
        preview('mon', DateTime(2026, 10, 5, 7), 3000),
        preview('last-week', DateTime(2026, 10, 2, 7), 10000),
      ]);
      await pumpEventQueue();

      expect(cubit.state.status, HistoryStatus.ready);
      expect(cubit.state.workouts, hasLength(3));
      expect(cubit.state.thisWeek.workouts, 2);
      expect(cubit.state.thisWeek.distanceM, 8000);
      expect(cubit.state.thisWeek.duration, const Duration(hours: 1));
      await cubit.close();
    });

    test('refresh uploads first, then imports; errors are reported', () async {
      when(sync.syncPending).thenAnswer((_) async => const Success(1));
      when(workouts.refreshFromServer)
          .thenAnswer((_) async => const Err(NetworkFailure()));
      final cubit = build(t0);

      await cubit.refresh();

      verifyInOrder([sync.syncPending, workouts.refreshFromServer]);
      expect(cubit.state.refreshing, isFalse);
      expect(cubit.state.errorMessage, 'You appear to be offline.');
      await cubit.close();
    });
  });

  group('WorkoutDetailCubit', () {
    final workout = Workout(
      id: 'w1',
      activity: ActivityType.run,
      startedAt: t0,
      endedAt: t0,
      duration: Duration.zero,
      distanceM: 0,
      elevationGainM: 0,
      maxSpeedMps: 0,
      splits: const [],
      route: const [GeoPoint(-30.03, -51.24), GeoPoint(-30.04, -51.24)],
      synced: true,
    );

    test('shows the workout even when incidents cannot load', () async {
      final workouts = _MockWorkouts();
      final incidents = _MockIncidents();
      when(() => workouts.getWorkout('w1'))
          .thenAnswer((_) async => Success(workout));
      when(
        () => incidents.nearRoute(
          workoutId: any(named: 'workoutId'),
          route: any(named: 'route'),
          synced: any(named: 'synced'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      final cubit = WorkoutDetailCubit(
        getWorkout: GetWorkout(workouts),
        getIncidents: GetIncidentsNearWorkout(incidents),
      );
      await cubit.load('w1');

      expect(cubit.state.workout, workout);
      expect(cubit.state.incidents, isEmpty);
      expect(cubit.state.incidentsError, 'You appear to be offline.');
      await cubit.close();
    });

    test('lists incidents near an uploaded route', () async {
      final workouts = _MockWorkouts();
      final incidents = _MockIncidents();
      when(() => workouts.getWorkout('w1'))
          .thenAnswer((_) async => Success(workout));
      when(
        () => incidents.nearRoute(
          workoutId: 'w1',
          route: any(named: 'route'),
          synced: true,
        ),
      ).thenAnswer((_) async => Success([incidentAt('pothole')]));

      final cubit = WorkoutDetailCubit(
        getWorkout: GetWorkout(workouts),
        getIncidents: GetIncidentsNearWorkout(incidents),
      );
      await cubit.load('w1');

      expect(cubit.state.incidents!.single.id, 'pothole');
      await cubit.close();
    });
  });
}

extension on ActiveWorkout {
  /// The workout as it would be after recording [recorded].
  ActiveWorkout withPoints(List<TrackPoint> recorded) =>
      recorded.fold(this, (w, p) => w.addPoint(p));
}
