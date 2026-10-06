import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/app.dart';
import 'package:pulseroute/core/di/injection.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/features/auth/domain/entities/app_user.dart';
import 'package:pulseroute/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulseroute/features/auth/presentation/bloc/session_bloc.dart';
import 'package:pulseroute/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:pulseroute/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:pulseroute/features/tracking/domain/repositories/location_repository.dart';
import 'package:pulseroute/features/tracking/domain/repositories/workout_recorder_repository.dart';
import 'package:pulseroute/features/tracking/domain/usecases/finish_workout.dart';
import 'package:pulseroute/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:pulseroute/features/workouts/domain/repositories/workout_sync_repository.dart';

import 'helpers/mocks.dart';

class _MockLocation extends Mock implements LocationRepository;

class _MockRecorder extends Mock implements WorkoutRecorderRepository;

class _MockSync extends Mock implements WorkoutSyncRepository;

void main() {
  const user = AppUser(id: 'u1', email: 'ana@example.com');
  late MockAuthRepository auth;
  late StreamController<AppUser?> userChanges;
  late ThemeCubit themeCubit;

  setUp(() {
    final settings = MockSettingsRepository();
    when(() => settings.themeMode).thenReturn(ThemeMode.light);
    when(() => settings.setThemeMode(ThemeMode.dark)).thenAnswer((_) async {});
    themeCubit = ThemeCubit(settings);

    auth = MockAuthRepository();
    userChanges = StreamController<AppUser?>.broadcast();
    when(() => auth.userChanges).thenAnswer((_) => userChanges.stream);
    when(() => auth.signOut()).thenAnswer((_) async => const Success(null));

    final location = _MockLocation();
    when(location.isBatteryOptimized).thenAnswer((_) async => false);
    final recorder = _MockRecorder();
    when(recorder.loadActive).thenAnswer((_) async => const Success(null));

    // The router creates screen blocs from the service locator.
    getIt
      ..registerLazySingleton(
        () => TrackingBloc(
          location: location,
          recorder: recorder,
          finishWorkout: FinishWorkout(recorder: recorder, sync: _MockSync()),
          newId: () => 'w1',
        ),
        dispose: (bloc) => bloc.close(),
      )
      ..registerFactory(
        () => SignInCubit(
          signInWithPassword: SignInWithPassword(auth),
          sendMagicLink: SendMagicLink(auth),
        ),
      );
  });

  tearDown(() async {
    await userChanges.close();
    await themeCubit.close();
    await getIt.reset();
  });

  Future<SessionBloc> pumpApp(WidgetTester tester, {AppUser? user}) async {
    when(() => auth.currentUser).thenReturn(user);
    final session = SessionBloc(repository: auth, signOut: SignOut(auth));
    addTearDown(session.close);
    await tester.pumpWidget(
      PulseRouteApp(themeCubit: themeCubit, sessionBloc: session),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('signed-out users land on the sign in screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Track'), findsNothing);
  });

  testWidgets('signed-in users see the tabs and can switch', (tester) async {
    await pumpApp(tester, user: user);

    expect(find.byKey(const Key('startButton')), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No workouts yet'), findsOneWidget);
  });

  testWidgets('signing in from the auth provider opens the app', (
    tester,
  ) async {
    await pumpApp(tester);

    userChanges.add(user);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startButton')), findsOneWidget);
  });

  testWidgets('theme and sign out from Settings', (tester) async {
    await pumpApp(tester, user: user);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('ana@example.com'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
