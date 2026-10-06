import 'package:equatable/equatable.dart';

import '../../../../core/domain/activity_type.dart';
import 'track_point.dart';

/// Whether an unfinished workout is currently recording.
enum ActiveWorkoutStatus { recording, paused }

/// A workout in progress. Persisted after every change so it survives the
/// app being killed.
///
/// Moving time is tracked with a wall clock: [activeDuration] holds the time
/// accumulated before the last resume and [resumedAt] when it last resumed.
class ActiveWorkout extends Equatable {
  const ActiveWorkout({
    required this.id,
    required this.activity,
    required this.startedAt,
    required this.status,
    this.activeDuration = Duration.zero,
    this.resumedAt,
    this.segment = 0,
    this.points = const [],
  });

  /// Starts recording now.
  factory ActiveWorkout.start({
    required String id,
    required ActivityType activity,
    required DateTime now,
  }) => ActiveWorkout(
    id: id,
    activity: activity,
    startedAt: now,
    status: ActiveWorkoutStatus.recording,
    resumedAt: now,
  );

  final String id;
  final ActivityType activity;
  final DateTime startedAt;
  final ActiveWorkoutStatus status;
  final Duration activeDuration;
  final DateTime? resumedAt;

  /// Current segment; increases on every resume.
  final int segment;
  final List<TrackPoint> points;

  bool get isRecording => status == ActiveWorkoutStatus.recording;

  /// Moving time up to [now].
  Duration elapsed(DateTime now) {
    final since = resumedAt;
    if (!isRecording || since == null) return activeDuration;
    final running = now.difference(since);
    return activeDuration + (running.isNegative ? Duration.zero : running);
  }

  ActiveWorkout pause(DateTime now) => isRecording
      ? _copy(
          status: ActiveWorkoutStatus.paused,
          activeDuration: elapsed(now),
          resumedAt: null,
        )
      : this;

  ActiveWorkout resume(DateTime now) => isRecording
      ? this
      : _copy(
          status: ActiveWorkoutStatus.recording,
          resumedAt: now,
          segment: segment + 1,
        );

  /// Starts a new segment without pausing, e.g. after recovering from a
  /// crash, so no distance is drawn across the gap.
  ActiveWorkout newSegment() => _copy(segment: segment + 1);

  ActiveWorkout addPoint(TrackPoint point) => _copy(points: [...points, point]);

  ActiveWorkout _copy({
    ActiveWorkoutStatus? status,
    Duration? activeDuration,
    Object? resumedAt = _keep,
    int? segment,
    List<TrackPoint>? points,
  }) {
    return ActiveWorkout(
      id: id,
      activity: activity,
      startedAt: startedAt,
      status: status ?? this.status,
      activeDuration: activeDuration ?? this.activeDuration,
      resumedAt: identical(resumedAt, _keep)
          ? this.resumedAt
          : resumedAt as DateTime?,
      segment: segment ?? this.segment,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [
    id,
    activity,
    startedAt,
    status,
    activeDuration,
    resumedAt,
    segment,
    points,
  ];
}

const Object _keep = Object();
