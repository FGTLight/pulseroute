import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/app.dart';
import 'package:pulseroute/core/connectivity/connectivity_cubit.dart';
import 'package:pulseroute/core/di/injection.dart';
import 'package:pulseroute/core/domain/distance_unit.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/features/auth/domain/entities/app_user.dart';
import 'package:pulseroute/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulseroute/features/auth/presentation/bloc/session_bloc.dart';
import 'package:pulseroute/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:pulseroute/features/incidents/domain/repositories/alert_notifier.dart';
import 'package:pulseroute/features/incidents/domain/repositories/incident_repository.dart';
import 'package:pulseroute/features/incidents/domain/usecases/incident_usecases.dart';
import 'package:pulseroute/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:pulseroute/features/incidents/presentation/cubit/proximity_alert_cubit.dart';
import 'package:pulseroute/features/settings/presentation/cubit/account_cubit.dart';
import 'package:pulseroute/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pulseroute/features/tracking/domain/repositories/location_repository.dart';
import 'package:pulseroute/features/tracking/domain/repositories/workout_recorder_repository.dart';
import 'package:pulseroute/features/tracking/domain/usecases/finish_workout.dart';
import 'package:pulseroute/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:pulseroute/features/workouts/domain/repositories/workout_repository.dart';
import 'package:pulseroute/features/workouts/domain/repositories/workout_sync_repository.dart';
import 'package:pulseroute/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:pulseroute/features/workouts/presentation/cubit/history_cubit.dart';

import 'helpers/fakes.dart';
import 'helpers/mocks.dart';

class _MockLocation extends Mock implements LocationRepository;

class _MockRecorder extends Mock implements WorkoutRecorderRepository;

class _MockSync extends Mock implements WorkoutSyncRepository;

class _MockIncidents extends Mock implements IncidentRepository;

class _MockNotifier extends Mock implements AlertNotifier;

class _MockWorkouts extends Mock implements WorkoutRepository;

/// End-to-end navigation of the app with every backend mocked.
void main() {
  const user = AppUser(id: 'u1', email: 'ana@example.com');
  late MockAuthRepository auth;
  late StreamController<AppUser?> userChanges;
  late InMemorySettingsRepository settingsRepository;
  late SettingsCubit settings;

  setUpAll(() => registerFallbackValue(IncidentsBloc.fallbackCenter));

  setUp(() {
    settingsRepository = InMemorySettingsRepository();
    settings = SettingsCubit(settingsRepository);

    auth = MockAuthRepository();
    userChanges = StreamController<AppUser?>.broadcast();
    when(() => auth.userChanges).thenAnswer((_) => userChanges.stream);
    when(() => auth.signOut()).thenAnswer((_) async => const Success(null));

    final location = _MockLocation();
    when(location.isBatteryOptimized).thenAnswer((_) async => false);
    final recorder = _MockRecorder();
    when(recorder.loadActive).thenAnswer((_) async => const Success(null));
    final sync = _MockSync();
    when(sync.syncPending).thenAnswer((_) async => const Success(0));
    final incidents = _MockIncidents();
    when(incidents.watchChanges).thenAnswer((_) => const Stream.empty());
    when(() => incidents.nearby(any(), radiusM: any(named: 'radiusM')))
        .thenAnswer((_) async => const Success([]));
    final workouts = _MockWorkouts();
    when(workouts.watchHistory).thenAnswer((_) => Stream.value(const []));

    // The router reads screen blocs from the service locator.
    getIt
      ..registerLazySingleton(
        () => TrackingBloc(
          location: location,
          recorder: recorder,
          finishWorkout: FinishWorkout(recorder: recorder, sync: sync),
          newId: () => 'w1',
        ),
        dispose: (bloc) => bloc.close(),
      )
      ..registerLazySingleton(
        () => IncidentsBloc(
          getNearby: GetNearbyIncidents(incidents),
          vote: VoteOnIncident(incidents),
          repository: incidents,
          locate: () async => null,
        )..add(const IncidentsStarted()),
        dispose: (bloc) => bloc.close(),
      )
      ..registerLazySingleton(
        () => ProximityAlertCubit(
          tracking: getIt<TrackingBloc>().stream,
          incidents: () => getIt<IncidentsBloc>().state.incidents,
          notifier: _MockNotifier(),
          settings: settingsRepository,
        ),
        dispose: (cubit) => cubit.close(),
      )
      ..registerLazySingleton(
        () => ConnectivityCubit(
          onlineChanges: const Stream.empty(),
          isOnline: () async => true,
        ),
        dispose: (cubit) => cubit.close(),
      )
      ..registerFactory(
        () => SignInCubit(
          signInWithPassword: SignInWithPassword(auth),
          sendMagicLink: SendMagicLink(auth),
        ),
      )
      ..registerFactory(
        () => HistoryCubit(
          watchHistory: WatchHistory(workouts),
          refreshHistory: RefreshHistory(workouts, sync),
          deleteWorkout: DeleteWorkout(workouts),
        ),
      )
      ..registerFactory(() => AccountCubit(DeleteAccount(auth, () async {})));
  });

  tearDown(() async {
    await userChanges.close();
    await settings.close();
    await getIt.reset();
  });

  Future<void> pumpApp(WidgetTester tester, {AppUser? user}) async {
    when(() => auth.currentUser).thenReturn(user);
    final session = SessionBloc(repository: auth, signOut: SignOut(auth));
    addTearDown(session.close);
    await tester.pumpWidget(
      PulseRouteApp(settingsCubit: settings, sessionBloc: session),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('first launch shows onboarding, then sign in', (tester) async {
    settingsRepository.onboardingDone = false;
    settings = SettingsCubit(settingsRepository);
    await pumpApp(tester);

    expect(find.text('Map every run and ride'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('onboardingNext')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Welcome back'), findsOneWidget);
    expect(settingsRepository.onboardingDone, isTrue);
  });

  testWidgets('signed-out users land on the sign in screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Track'), findsNothing);
  });

  testWidgets('signing in opens the app and tabs switch', (tester) async {
    await pumpApp(tester);

    userChanges.add(user);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('startButton')), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No workouts yet'), findsOneWidget);
  });

  testWidgets('settings change theme and units, and sign out', (tester) async {
    // A tall phone, so the whole settings list fits above the nav bar.
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await pumpApp(tester, user: user);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('ana@example.com'), findsOneWidget);

    await tester.tap(find.text('Miles'));
    await tester.pumpAndSettle();
    expect(settingsRepository.unit, DistanceUnit.mi);

    await tester.ensureVisible(find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.ensureVisible(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
