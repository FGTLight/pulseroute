import 'package:flutter/material.dart' show ThemeMode;
import 'package:pulseroute/core/domain/distance_unit.dart';
import 'package:pulseroute/features/settings/domain/settings_repository.dart';

/// [SettingsRepository] kept in memory, for widget and integration tests.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({this.onboardingDone = true});

  @override
  ThemeMode themeMode = ThemeMode.light;

  @override
  DistanceUnit unit = DistanceUnit.km;

  @override
  bool alertsEnabled = true;

  @override
  int alertRadiusM = SettingsRepository.defaultAlertRadiusM;

  @override
  bool onboardingDone;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => themeMode = mode;

  @override
  Future<void> setUnit(DistanceUnit unit) async => this.unit = unit;

  @override
  Future<void> setAlertsEnabled({required bool enabled}) async =>
      alertsEnabled = enabled;

  @override
  Future<void> setAlertRadiusM(int meters) async => alertRadiusM = meters;

  @override
  Future<void> setOnboardingDone() async => onboardingDone = true;
}
