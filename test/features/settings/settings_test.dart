import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/connectivity/connectivity_cubit.dart';
import 'package:pulseroute/core/domain/distance_unit.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/core/utils/form_status.dart';
import 'package:pulseroute/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulseroute/features/settings/domain/app_settings.dart';
import 'package:pulseroute/features/settings/presentation/cubit/account_cubit.dart';
import 'package:pulseroute/features/settings/presentation/cubit/settings_cubit.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';

void main() {
  group('SettingsCubit', () {
    late InMemorySettingsRepository repository;

    setUp(() => repository = InMemorySettingsRepository());

    test('starts from the persisted values', () {
      repository
        ..unit = DistanceUnit.mi
        ..alertRadiusM = 200;
      final cubit = SettingsCubit(repository);
      expect(cubit.state.unit, DistanceUnit.mi);
      expect(cubit.state.alertRadiusM, 200);
    });

    blocTest<SettingsCubit, AppSettings>(
      'persists every change',
      build: () => SettingsCubit(repository),
      act: (cubit) async {
        await cubit.setUnit(DistanceUnit.mi);
        await cubit.setThemeMode(ThemeMode.dark);
        await cubit.setAlertsEnabled(enabled: false);
        await cubit.setAlertRadius(50);
      },
      verify: (cubit) {
        expect(repository.unit, DistanceUnit.mi);
        expect(repository.themeMode, ThemeMode.dark);
        expect(repository.alertsEnabled, isFalse);
        expect(repository.alertRadiusM, 50);
        expect(cubit.state.alertRadiusM, 50);
      },
    );

    blocTest<SettingsCubit, AppSettings>(
      'completing onboarding is remembered',
      build: () =>
          SettingsCubit(InMemorySettingsRepository(onboardingDone: false)),
      act: (cubit) => cubit.completeOnboarding(),
      expect: () => [
        isA<AppSettings>().having((s) => s.onboardingDone, 'done', isTrue),
      ],
    );
  });

  group('Account deletion', () {
    test('clears the device data only after the server succeeded', () async {
      final auth = MockAuthRepository();
      var cleared = 0;
      Future<void> clear() async => cleared++;

      when(auth.deleteAccount)
          .thenAnswer((_) async => const Err(NetworkFailure()));
      final cubit = AccountCubit(DeleteAccount(auth, clear));
      await cubit.deleteAccount();
      expect(cubit.state.status, FormStatus.failure);
      expect(cubit.state.error, 'You appear to be offline.');
      expect(cleared, 0);

      when(auth.deleteAccount).thenAnswer((_) async => const Success(null));
      await cubit.deleteAccount();
      expect(cubit.state.status, FormStatus.success);
      expect(cleared, 1);
      await cubit.close();
    });
  });

  group('ConnectivityCubit', () {
    test('tracks the connection and syncs when it comes back', () async {
      final changes = StreamController<bool>();
      var reconnects = 0;
      final cubit = ConnectivityCubit(
        onlineChanges: changes.stream,
        isOnline: () async => false,
        onReconnect: () async => reconnects++,
      );
      await pumpEventQueue();
      expect(cubit.state, isFalse);

      changes.add(true);
      await pumpEventQueue();
      expect(cubit.state, isTrue);
      expect(reconnects, 1);

      changes.add(true); // no change, no extra sync
      await pumpEventQueue();
      expect(reconnects, 1);

      await cubit.close();
      await changes.close();
    });
  });
}
