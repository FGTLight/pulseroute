import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_repository.dart';

/// [SettingsRepository] stored in SharedPreferences.
class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  static const _themeKey = 'theme_mode';

  final SharedPreferences _prefs;

  @override
  ThemeMode get themeMode => ThemeMode.values.firstWhere(
    (m) => m.name == _prefs.getString(_themeKey),
    orElse: () => ThemeMode.system,
  );

  @override
  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeKey, mode.name);
}
