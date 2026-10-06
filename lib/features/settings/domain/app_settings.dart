import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../../core/domain/distance_unit.dart';

/// User preferences.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.unit = DistanceUnit.km,
    this.alertsEnabled = true,
    this.alertRadiusM = 100,
    this.onboardingDone = false,
  });

  static const alertRadiusOptions = [50, 100, 150, 200, 300];

  final ThemeMode themeMode;
  final DistanceUnit unit;
  final bool alertsEnabled;
  final int alertRadiusM;

  /// Whether the first-launch introduction was completed.
  final bool onboardingDone;

  AppSettings copyWith({
    ThemeMode? themeMode,
    DistanceUnit? unit,
    bool? alertsEnabled,
    int? alertRadiusM,
    bool? onboardingDone,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      unit: unit ?? this.unit,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      alertRadiusM: alertRadiusM ?? this.alertRadiusM,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    unit,
    alertsEnabled,
    alertRadiusM,
    onboardingDone,
  ];
}
