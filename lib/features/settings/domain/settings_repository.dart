import 'package:flutter/material.dart' show ThemeMode;

/// Persists user preferences.
abstract interface class SettingsRepository {
  ThemeMode get themeMode;

  Future<void> setThemeMode(ThemeMode mode);
}
