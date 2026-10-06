import 'package:equatable/equatable.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/domain/geo_point.dart';

/// A finished workout as shown in the history list: key numbers and a
/// simplified route, without the full GPS track.
class WorkoutPreview extends Equatable {
  const WorkoutPreview({
    required this.id,
    required this.activity,
    required this.startedAt,
    required this.duration,
    required this.distanceM,
    required this.preview,
    this.synced = false,
  });

  final String id;
  final ActivityType activity;
  final DateTime startedAt;
  final Duration duration;
  final double distanceM;
  final List<GeoPoint> preview;
  final bool synced;

  double get avgSpeedMps {
    final seconds = duration.inMilliseconds / 1000;
    return seconds <= 0 ? 0 : distanceM / seconds;
  }

  @override
  List<Object?> get props => [
    id,
    activity,
    startedAt,
    duration,
    distanceM,
    preview,
    synced,
  ];
}

/// Totals shown above the history list.
class HistoryTotals extends Equatable {
  const HistoryTotals({
    required this.workouts,
    required this.distanceM,
    required this.duration,
  });

  /// Totals of the workouts started on or after [since].
  factory HistoryTotals.since(List<WorkoutPreview> all, DateTime since) {
    final recent = all.where((w) => !w.startedAt.isBefore(since));
    return HistoryTotals(
      workouts: recent.length,
      distanceM: recent.fold(0, (sum, w) => sum + w.distanceM),
      duration: recent.fold(Duration.zero, (sum, w) => sum + w.duration),
    );
  }

  final int workouts;
  final double distanceM;
  final Duration duration;

  @override
  List<Object?> get props => [workouts, distanceM, duration];
}
