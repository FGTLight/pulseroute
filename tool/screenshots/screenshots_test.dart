// Renders README screenshots and the portfolio cover from the real widgets
// with fake data. Map tiles cannot load in tests, so routes are drawn with
// the app's RoutePainter on a plain background instead of Google Maps.
//
// Run: flutter test tool/screenshots/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/connectivity/connectivity_cubit.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/core/domain/distance_unit.dart';
import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/core/theme/app_theme.dart';
import 'package:pulseroute/features/auth/domain/entities/app_user.dart';
import 'package:pulseroute/features/auth/presentation/bloc/session_bloc.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident.dart';
import 'package:pulseroute/features/incidents/domain/repositories/incident_repository.dart';
import 'package:pulseroute/features/incidents/domain/services/proximity_alert_engine.dart';
import 'package:pulseroute/features/incidents/domain/usecases/incident_usecases.dart';
import 'package:pulseroute/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:pulseroute/features/incidents/presentation/cubit/proximity_alert_cubit.dart';
import 'package:pulseroute/features/incidents/presentation/cubit/report_incident_cubit.dart';
import 'package:pulseroute/features/incidents/presentation/screens/incidents_screen.dart';
import 'package:pulseroute/features/incidents/presentation/screens/report_incident_screen.dart';
import 'package:pulseroute/features/incidents/presentation/widgets/proximity_alert_banner.dart';
import 'package:pulseroute/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pulseroute/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pulseroute/features/tracking/domain/entities/active_workout.dart';
import 'package:pulseroute/features/tracking/domain/entities/track_point.dart';
import 'package:pulseroute/features/tracking/domain/services/stats_accumulator.dart';
import 'package:pulseroute/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:pulseroute/features/tracking/presentation/widgets/tracking_panel.dart';
import 'package:pulseroute/features/workouts/domain/entities/workout.dart';
import 'package:pulseroute/features/workouts/domain/entities/workout_preview.dart';
import 'package:pulseroute/features/workouts/domain/repositories/workout_repository.dart';
import 'package:pulseroute/features/workouts/domain/repositories/workout_sync_repository.dart';
import 'package:pulseroute/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:pulseroute/features/workouts/presentation/cubit/history_cubit.dart';
import 'package:pulseroute/features/workouts/presentation/screens/history_screen.dart';
import 'package:pulseroute/features/workouts/presentation/widgets/route_thumbnail.dart';
import 'package:pulseroute/features/workouts/presentation/widgets/workout_summary_view.dart';

import '../../test/helpers/fakes.dart';

class _MockTracking extends MockBloc<TrackingEvent, TrackingState>
    implements TrackingBloc;

class _MockAlerts extends MockCubit<ProximityAlertState>
    implements ProximityAlertCubit;

class _MockIncidents extends Mock implements IncidentRepository;

class _MockWorkouts extends Mock implements WorkoutRepository;

class _MockSync extends Mock implements WorkoutSyncRepository;

class _MockPhotos extends Mock implements PhotoRepository;

class _MockSession extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc;

const phone = Size(360, 780);
final now = DateTime(2026, 10, 6, 7, 40);
const _mPerDegLat = 111195.08;

/// A loop along the Porto Alegre waterfront, as recorded track points.
List<TrackPoint> waterfrontLoop() {
  const anchors = [
    GeoPoint(-30.0336, -51.2372),
    GeoPoint(-30.0369, -51.2414),
    GeoPoint(-30.0447, -51.2398),
    GeoPoint(-30.0502, -51.2389),
    GeoPoint(-30.0480, -51.2340),
    GeoPoint(-30.0400, -51.2330),
    GeoPoint(-30.0345, -51.2350),
  ];
  final points = <TrackPoint>[];
  var t = now.subtract(const Duration(minutes: 31));
  for (var i = 0; i < anchors.length - 1; i++) {
    final a = anchors[i];
    final b = anchors[i + 1];
    for (var s = 0; s < 25; s++) {
      final f = s / 25;
      // A little wobble so it looks like a real GPS track.
      final wobble = (s.isEven ? 1 : -1) * 0.00004;
      points.add(
        TrackPoint(
          lat: a.lat + (b.lat - a.lat) * f + wobble,
          lng: a.lng + (b.lng - a.lng) * f,
          timestamp: t,
          segment: 0,
          altitudeM: 10 + 8 * (i % 3) + s * 0.2,
        ),
      );
      t = t.add(const Duration(seconds: 6));
    }
  }
  return points;
}

final incidents = [
  Incident(
    id: 'dark',
    category: IncidentCategory.darkArea,
    severity: IncidentSeverity.high,
    description: 'Waterfront path has no working lights after 8 pm.',
    location: const GeoPoint(-30.0391, -51.2405),
    radiusM: 180,
    confirmations: 6,
    createdAt: now.subtract(const Duration(days: 3)),
    expiresAt: now.add(const Duration(days: 11)),
  ),
  Incident(
    id: 'pothole',
    category: IncidentCategory.pothole,
    severity: IncidentSeverity.medium,
    description: 'Deep pothole on the bike lane, hard to see at night.',
    location: const GeoPoint(-30.0391 - 450 / _mPerDegLat, -51.2398),
    confirmations: 3,
    createdAt: now.subtract(const Duration(days: 1)),
    expiresAt: now.add(const Duration(days: 13)),
  ),
  Incident(
    id: 'crossing',
    category: IncidentCategory.dangerousCrossing,
    severity: IncidentSeverity.high,
    description: 'Cars run the red light at this crossing.',
    location: const GeoPoint(-30.0336, -51.2372),
    confirmations: 8,
    createdAt: now.subtract(const Duration(days: 6)),
    expiresAt: now.add(const Duration(days: 8)),
  ),
  Incident(
    id: 'closed',
    category: IncidentCategory.closedStreet,
    severity: IncidentSeverity.medium,
    description: 'Path closed for construction, detour through the park.',
    location: const GeoPoint(-30.0502, -51.2389),
    confirmations: 2,
    createdAt: now.subtract(const Duration(hours: 5)),
    expiresAt: now.add(const Duration(days: 14)),
  ),
];

Future<void> loadFonts() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['USERPROFILE']}/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'black', 'light']) {
    roboto.addFont(read('roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('materialicons-regular.otf'))).load();
}

/// Placeholder for map tiles: the route drawn on a soft "map" background.
class FakeMap extends StatelessWidget {
  const FakeMap({required this.route, super.key});

  final List<GeoPoint> route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Color.alphaBlend(
        scheme.primary.withValues(alpha: .04),
        scheme.surfaceContainerHighest,
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: RoutePainter(
          route: route,
          color: scheme.primary,
          strokeWidth: 6,
          padding: 48,
        ),
      ),
    );
  }
}

void main() {
  late SettingsCubit settings;
  late IncidentsBloc incidentsBloc;
  late ConnectivityCubit connectivity;
  late _MockSession session;

  setUpAll(() async {
    await loadFonts();
    registerFallbackValue(const GeoPoint(0, 0));
  });

  setUp(() async {
    settings = SettingsCubit(InMemorySettingsRepository());
    connectivity = ConnectivityCubit(
      onlineChanges: const Stream.empty(),
      isOnline: () async => true,
    );
    session = _MockSession();
    when(() => session.state).thenReturn(
      const SessionState.authenticated(
        AppUser(id: 'u1', email: 'ana@example.com'),
      ),
    );
    final repo = _MockIncidents();
    when(repo.watchChanges).thenAnswer((_) => const Stream.empty());
    when(() => repo.currentUserId).thenReturn('u1');
    when(() => repo.nearby(any(), radiusM: any(named: 'radiusM')))
        .thenAnswer((_) async => Success(incidents));
    incidentsBloc = IncidentsBloc(
      getNearby: GetNearbyIncidents(repo),
      vote: VoteOnIncident(repo),
      repository: repo,
      locate: () async => const GeoPoint(-30.0400, -51.2380),
      clock: () => now,
    )..add(const IncidentsStarted());
  });

  Widget app(Widget child, {ThemeMode mode = ThemeMode.light}) =>
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider<SessionBloc>.value(value: session),
          BlocProvider.value(value: incidentsBloc),
          BlocProvider.value(value: connectivity),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: child,
        ),
      );

  Widget trackingScreen() {
    final points = waterfrontLoop();
    final workout = ActiveWorkout(
      id: 'w1',
      activity: ActivityType.run,
      startedAt: now.subtract(const Duration(minutes: 31)),
      status: ActiveWorkoutStatus.recording,
      resumedAt: now.subtract(const Duration(minutes: 31)),
      points: points,
    );
    final stats = StatsAccumulator.fromPoints(points)
        .toStats(const Duration(minutes: 21, seconds: 30));
    final tracking = _MockTracking();
    whenListen(
      tracking,
      const Stream<TrackingState>.empty(),
      initialState: TrackingState(
        status: TrackingStatus.recording,
        workout: workout,
        stats: stats,
        position: points.last.point,
      ),
    );
    final alerts = _MockAlerts();
    whenListen(
      alerts,
      const Stream<ProximityAlertState>.empty(),
      initialState: ProximityAlertState(
        latest: ProximityAlert(incident: incidents[1], distanceM: 85),
      ),
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<TrackingBloc>.value(value: tracking),
        BlocProvider<ProximityAlertCubit>.value(value: alerts),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: FakeMap(route: [for (final p in points) p.point]),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: ProximityAlertBanner()),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: TrackingPanel(unit: DistanceUnit.km),
            ),
          ],
        ),
      ),
    );
  }

  Widget historyScreen() {
    final workouts = _MockWorkouts();
    final route = [for (final p in waterfrontLoop()) p.point];
    List<GeoPoint> shift(double dLat, double dLng) => [
      for (final p in route) GeoPoint(p.lat + dLat, p.lng + dLng),
    ];
    when(workouts.watchHistory).thenAnswer(
      (_) => Stream.value([
        WorkoutPreview(
          id: '1',
          activity: ActivityType.run,
          startedAt: now,
          duration: const Duration(minutes: 30, seconds: 48),
          distanceM: 5820,
          preview: route,
          synced: true,
        ),
        WorkoutPreview(
          id: '2',
          activity: ActivityType.bike,
          startedAt: now.subtract(const Duration(days: 1, hours: 2)),
          duration: const Duration(hours: 1, minutes: 4),
          distanceM: 24310,
          preview: [for (final p in shift(0, 0)) GeoPoint(p.lng / -1.7, p.lat)],
          synced: true,
        ),
        WorkoutPreview(
          id: '3',
          activity: ActivityType.run,
          startedAt: now.subtract(const Duration(days: 3)),
          duration: const Duration(minutes: 52, seconds: 10),
          distanceM: 10040,
          preview: route.reversed.toList(),
        ),
      ]),
    );
    return BlocProvider(
      create: (_) => HistoryCubit(
        watchHistory: WatchHistory(workouts),
        refreshHistory: RefreshHistory(workouts, _MockSync()),
        deleteWorkout: DeleteWorkout(workouts),
        clock: () => now,
      ),
      child: const HistoryScreen(),
    );
  }

  Widget detailScreen() {
    final points = waterfrontLoop();
    final workout = Workout(
      id: '1',
      activity: ActivityType.run,
      startedAt: now.subtract(const Duration(minutes: 31)),
      endedAt: now,
      duration: const Duration(minutes: 30, seconds: 48),
      distanceM: 5820,
      elevationGainM: 34,
      maxSpeedMps: 4.1,
      splits: const [
        Duration(minutes: 5, seconds: 24),
        Duration(minutes: 5, seconds: 11),
        Duration(minutes: 5, seconds: 2),
        Duration(minutes: 5, seconds: 19),
        Duration(minutes: 5, seconds: 8),
      ],
      route: [for (final p in points) p.point],
      synced: true,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: WorkoutSummaryView(
        workout: workout,
        mapBuilder: (route) => FakeMap(route: route),
      ),
    );
  }

  Widget reportScreen() => BlocProvider(
    create: (_) => ReportIncidentCubit(
      location: const GeoPoint(-30.0391, -51.2405),
      reportIncident: ReportIncident(_MockIncidents()),
      photos: _MockPhotos(),
    )..selectCategory(IncidentCategory.darkArea),
    child: const ReportIncidentScreen(),
  );

  Future<void> capture(
    WidgetTester tester,
    Widget screen,
    String name, {
    ThemeMode mode = ThemeMode.light,
    Future<void> Function(WidgetTester tester)? prepare,
    bool settle = true,
  }) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    debugDisableShadows = false;
    const key = Key('shot');
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: app(screen, mode: mode),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Native map views keep scheduling frames in tests: advance time.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    await prepare?.call(tester);
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('screenshots/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;
    tester.view.reset();
  }

  testWidgets('tracking', (t) => capture(t, trackingScreen(), 'tracking'));
  testWidgets('history', (t) => capture(t, historyScreen(), 'history'));
  testWidgets('workout detail', (t) => capture(t, detailScreen(), 'detail'));
  testWidgets('report', (t) => capture(t, reportScreen(), 'report'));
  testWidgets('incidents (dark)', (t) async {
    // The bloc loads with real futures: let them finish first.
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    // The map view needs real tiles, so capture the list view.
    await capture(
      t,
      const IncidentsScreen(startWithList: true),
      'incidents_dark',
      mode: ThemeMode.dark,
    );
  });
  testWidgets('onboarding', (t) async {
    await capture(t, OnboardingScreen(onDone: () {}), 'onboarding');
  });

  testWidgets('portfolio cover', (tester) async {
    const size = Size(1280, 720);
    tester.view.physicalSize = size * 1.5;
    tester.view.devicePixelRatio = 1.5;
    debugDisableShadows = false;

    Widget phoneFrame(Widget screen, {double dy = 0}) => Transform.translate(
      offset: Offset(0, dy),
      child: Transform.scale(
        scale: 0.78,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: SizedBox.fromSize(
              size: phone,
              child: MediaQuery(
                data: const MediaQueryData(
                  size: phone,
                  padding: EdgeInsets.only(top: 24),
                ),
                child: app(screen),
              ),
            ),
          ),
        ),
      ),
    );

    const key = Key('cover');
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5A36), Color(0xFFE02F6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                phoneFrame(historyScreen(), dy: 24),
                const SizedBox(width: 8),
                phoneFrame(trackingScreen(), dy: -16),
                const SizedBox(width: 8),
                phoneFrame(detailScreen(), dy: 24),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('screenshots/portfolio_cover.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;
    tester.view.reset();
  });
}
