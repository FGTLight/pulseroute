import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/distance_unit.dart';
import '../../domain/app_settings.dart';
import '../../domain/settings_repository.dart';

/// Holds the [AppSettings] and persists every change.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository)
    : super(
        AppSettings(
          themeMode: _repository.themeMode,
          unit: _repository.unit,
          alertsEnabled: _repository.alertsEnabled,
          alertRadiusM: _repository.alertRadiusM,
          onboardingDone: _repository.onboardingDone,
        ),
      );

  final SettingsRepository _repository;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state.themeMode) return;
    emit(state.copyWith(themeMode: mode));
    await _repository.setThemeMode(mode);
  }

  Future<void> setUnit(DistanceUnit unit) async {
    if (unit == state.unit) return;
    emit(state.copyWith(unit: unit));
    await _repository.setUnit(unit);
  }

  Future<void> setAlertsEnabled({required bool enabled}) async {
    emit(state.copyWith(alertsEnabled: enabled));
    await _repository.setAlertsEnabled(enabled: enabled);
  }

  Future<void> completeOnboarding() async {
    emit(state.copyWith(onboardingDone: true));
    await _repository.setOnboardingDone();
  }

  Future<void> setAlertRadius(int meters) async {
    emit(state.copyWith(alertRadiusM: meters));
    await _repository.setAlertRadiusM(meters);
  }
}
