import 'package:flutter/material.dart' show ThemeMode;

import '../../../core/domain/distance_unit.dart';

/// Persists user preferences.
abstract interface class SettingsRepository {
  static const defaultAlertRadiusM = 100;

  ThemeMode get themeMode;

  Future<void> setThemeMode(ThemeMode mode);

  DistanceUnit get unit;

  Future<void> setUnit(DistanceUnit unit);

  /// Whether proximity alerts are shown while tracking.
  bool get alertsEnabled;

  Future<void> setAlertsEnabled({required bool enabled});

  /// Distance at which an incident on the path triggers an alert.
  int get alertRadiusM;

  Future<void> setAlertRadiusM(int meters);

  bool get onboardingDone;

  Future<void> setOnboardingDone();
}
