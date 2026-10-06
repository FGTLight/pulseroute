import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/database/app_database.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/core/utils/ewkt.dart';
import 'package:pulseroute/features/tracking/data/repositories/drift_workout_recorder_repository.dart';
import 'package:pulseroute/features/tracking/domain/entities/active_workout.dart';
import 'package:pulseroute/features/tracking/domain/entities/workout_stats.dart';
import 'package:pulseroute/features/workouts/data/datasources/workout_remote_data_source.dart';
import 'package:pulseroute/features/workouts/data/repositories/workout_sync_repository_impl.dart';
import 'package:pulseroute/features/workouts/domain/entities/workout.dart';

import '../../helpers/track_builders.dart';

class _MockRemote extends Mock implements WorkoutRemoteDataSource;

void main() {
  late AppDatabase db;
  late DriftWorkoutRecorderRepository recorder;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    registerFallbackValue(
      Workout(
        id: '',
        activity: ActivityType.run,
        startedAt: t0,
        endedAt: t0,
        duration: Duration.zero,
        distanceM: 0,
        elevationGainM: 0,
        maxSpeedMps: 0,
        splits: const [],
        route: const [],
      ),
    );
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recorder = DriftWorkoutRecorderRepository(db);
  });

  tearDown(() => db.close());

  final workout = ActiveWorkout.start(
    id: 'w1',
    activity: ActivityType.bike,
    now: t0,
  );

  test('an in-progress workout and its points survive a restart', () async {
    await recorder.saveState(workout);
    for (final p in straightRun(meters: 30)) {
      await recorder.appendPoint('w1', p);
    }
    final paused = workout.pause(t0.add(const Duration(minutes: 3)));
    await recorder.saveState(paused);

    final restored = (await recorder.loadActive()).valueOrNull!;
    expect(restored.id, 'w1');
    expect(restored.activity, ActivityType.bike);
    expect(restored.status, ActiveWorkoutStatus.paused);
    expect(restored.activeDuration, const Duration(minutes: 3));
    expect(restored.points, hasLength(4));
    // Millisecond timestamps are preserved (see build.yaml).
    expect(restored.points[1].timestamp, straightRun(meters: 30)[1].timestamp);
  });

  test('finished and discarded workouts are no longer active', () async {
    await recorder.saveState(workout);
    await recorder.finish(
      workout,
      stats: const WorkoutStats(distanceM: 10),
      splits: const [],
      endedAt: t0.add(const Duration(minutes: 1)),
    );
    expect((await recorder.loadActive()).valueOrNull, isNull);

    final other = ActiveWorkout.start(
      id: 'w2',
      activity: ActivityType.run,
      now: t0,
    );
    await recorder.saveState(other);
    await recorder.appendPoint('w2', pointAt(0, seconds: 0));
    await recorder.discard('w2');
    expect((await recorder.loadActive()).valueOrNull, isNull);
    // Points were removed with the workout (foreign key cascade).
    expect(await db.select(db.localTrackPoints).get(), isEmpty);
  });

  group('sync', () {
    late _MockRemote remote;
    late WorkoutSyncRepositoryImpl sync;

    setUp(() {
      remote = _MockRemote();
      when(() => remote.isSignedIn).thenReturn(true);
      sync = WorkoutSyncRepositoryImpl(db, remote);
    });

    Future<void> finishOne(String id) async {
      final w = ActiveWorkout.start(
        id: id,
        activity: ActivityType.run,
        now: t0,
      );
      await recorder.saveState(w);
      for (final p in straightRun(meters: 20)) {
        await recorder.appendPoint(id, p);
      }
      await recorder.finish(
        w,
        stats: const WorkoutStats(
          distanceM: 20,
          duration: Duration(seconds: 7),
        ),
        splits: const [],
        endedAt: t0.add(const Duration(seconds: 7)),
      );
    }

    test('uploads pending workouts once', () async {
      when(() => remote.upsert(any())).thenAnswer((_) async {});
      await finishOne('w1');

      expect((await sync.syncPending()).valueOrNull, 1);
      expect((await sync.syncPending()).valueOrNull, 0);

      final uploaded =
          verify(() => remote.upsert(captureAny())).captured.single as Workout;
      expect(uploaded.id, 'w1');
      expect(uploaded.route, hasLength(3));
    });

    test('keeps workouts pending when the upload fails', () async {
      when(() => remote.upsert(any())).thenThrow(Exception('offline'));
      await finishOne('w1');

      expect((await sync.syncPending()).isSuccess, isFalse);

      when(() => remote.upsert(any())).thenAnswer((_) async {});
      expect((await sync.syncPending()).valueOrNull, 1);
    });
  });

  test('routes are sent to PostGIS as EWKT (lng lat order)', () {
    expect(Ewkt.lineString(const [GeoPoint(1, 2)]), isNull);
    expect(
      Ewkt.lineString(const [
        GeoPoint(-30.03, -51.22),
        GeoPoint(-30.04, -51.21),
      ]),
      'SRID=4326;LINESTRING(-51.220000 -30.030000,-51.210000 -30.040000)',
    );
  });
}
