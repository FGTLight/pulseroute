import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/settings_repository.dart';

/// Holds the app's [ThemeMode] and persists every change.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._repository) : super(_repository.themeMode);

  final SettingsRepository _repository;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _repository.setThemeMode(mode);
  }
}
