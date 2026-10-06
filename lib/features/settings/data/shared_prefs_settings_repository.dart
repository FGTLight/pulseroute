import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/distance_unit.dart';
import '../domain/settings_repository.dart';

/// [SettingsRepository] stored in SharedPreferences.
class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  static const _themeKey = 'theme_mode';
  static const _unitKey = 'distance_unit';
  static const _alertsKey = 'alerts_enabled';
  static const _radiusKey = 'alert_radius_m';
  static const _onboardingKey = 'onboarding_done';

  final SharedPreferences _prefs;

  @override
  ThemeMode get themeMode => ThemeMode.values.firstWhere(
    (m) => m.name == _prefs.getString(_themeKey),
    orElse: () => ThemeMode.system,
  );

  @override
  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeKey, mode.name);

  @override
  DistanceUnit get unit => DistanceUnit.values.firstWhere(
    (u) => u.name == _prefs.getString(_unitKey),
    orElse: () => DistanceUnit.km,
  );

  @override
  Future<void> setUnit(DistanceUnit unit) =>
      _prefs.setString(_unitKey, unit.name);

  @override
  bool get alertsEnabled => _prefs.getBool(_alertsKey) ?? true;

  @override
  Future<void> setAlertsEnabled({required bool enabled}) =>
      _prefs.setBool(_alertsKey, enabled);

  @override
  int get alertRadiusM =>
      _prefs.getInt(_radiusKey) ?? SettingsRepository.defaultAlertRadiusM;

  @override
  Future<void> setAlertRadiusM(int meters) => _prefs.setInt(_radiusKey, meters);

  @override
  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;

  @override
  Future<void> setOnboardingDone() => _prefs.setBool(_onboardingKey, true);
}
