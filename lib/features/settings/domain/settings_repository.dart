import 'package:flutter/material.dart' show ThemeMode;

/// Persists user preferences.
abstract interface class SettingsRepository {
  static const defaultAlertRadiusM = 100;

  ThemeMode get themeMode;

  Future<void> setThemeMode(ThemeMode mode);

  /// Whether proximity alerts are shown while tracking.
  bool get alertsEnabled;

  Future<void> setAlertsEnabled({required bool enabled});

  /// Distance at which an incident on the path triggers an alert.
  int get alertRadiusM;

  Future<void> setAlertRadiusM(int meters);
}
