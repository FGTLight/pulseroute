import 'package:equatable/equatable.dart';

/// Live numbers shown while tracking and stored when the workout ends.
class WorkoutStats extends Equatable {
  const WorkoutStats({
    this.distanceM = 0,
    this.duration = Duration.zero,
    this.elevationGainM = 0,
    this.currentSpeedMps = 0,
    this.maxSpeedMps = 0,
  });

  final double distanceM;

  /// Moving time: pauses are excluded.
  final Duration duration;
  final double elevationGainM;

  /// Speed over the last few seconds.
  final double currentSpeedMps;
  final double maxSpeedMps;

  /// Average moving speed.
  double get avgSpeedMps {
    final seconds = duration.inMilliseconds / 1000;
    return seconds <= 0 ? 0 : distanceM / seconds;
  }

  @override
  List<Object?> get props => [
    distanceM,
    duration,
    elevationGainM,
    currentSpeedMps,
    maxSpeedMps,
  ];
}
