part of 'tracking_bloc.dart';

/// Phases of the tracking screen.
enum TrackingStatus {
  /// Nothing recorded yet; the user can pick an activity and start.
  idle,

  /// Waiting for permissions / the first save before recording.
  starting,
  recording,
  paused,

  /// Computing and storing the final workout.
  saving,

  /// Done: [TrackingState.finishedWorkout] holds the summary.
  finished,
}

/// Everything the tracking screen renders.
final class TrackingState extends Equatable {
  const TrackingState({
    this.status = TrackingStatus.idle,
    this.activity = ActivityType.run,
    this.workout,
    this.stats = const WorkoutStats(),
    this.position,
    this.gpsWeak = false,
    this.accessIssue,
    this.showRationale = false,
    this.showBatteryTip = false,
    this.finishedWorkout,
    this.errorMessage,
  });

  final TrackingStatus status;
  final ActivityType activity;

  /// The workout being recorded (also while paused or saving).
  final ActiveWorkout? workout;
  final WorkoutStats stats;

  /// Latest known position, used to center the map.
  final GeoPoint? position;

  /// The last fix was not accurate enough to be recorded.
  final bool gpsWeak;

  /// Set when location is not available, to explain what to do.
  final LocationAccess? accessIssue;

  /// The UI should explain why location is needed before asking for it.
  final bool showRationale;

  /// Battery optimization may stop tracking with the screen off.
  final bool showBatteryTip;
  final Workout? finishedWorkout;
  final String? errorMessage;

  bool get isActive =>
      status == TrackingStatus.recording || status == TrackingStatus.paused;

  /// Route split by segment, so the map does not connect across pauses.
  List<List<GeoPoint>> get routeSegments {
    final segments = <List<GeoPoint>>[];
    int? current;
    for (final p in workout?.points ?? const <TrackPoint>[]) {
      if (p.segment != current) {
        segments.add([]);
        current = p.segment;
      }
      segments.last.add(p.point);
    }
    return segments;
  }

  TrackingState copyWith({
    TrackingStatus? status,
    ActivityType? activity,
    Object? workout = _keep,
    WorkoutStats? stats,
    GeoPoint? position,
    bool? gpsWeak,
    Object? accessIssue = _keep,
    bool? showRationale,
    bool? showBatteryTip,
    Object? finishedWorkout = _keep,
    String? errorMessage,
  }) {
    return TrackingState(
      status: status ?? this.status,
      activity: activity ?? this.activity,
      workout: identical(workout, _keep)
          ? this.workout
          : workout as ActiveWorkout?,
      stats: stats ?? this.stats,
      position: position ?? this.position,
      gpsWeak: gpsWeak ?? this.gpsWeak,
      accessIssue: identical(accessIssue, _keep)
          ? this.accessIssue
          : accessIssue as LocationAccess?,
      showRationale: showRationale ?? this.showRationale,
      showBatteryTip: showBatteryTip ?? this.showBatteryTip,
      finishedWorkout: identical(finishedWorkout, _keep)
          ? this.finishedWorkout
          : finishedWorkout as Workout?,
      // Errors are one-shot: they are cleared by the next state.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    activity,
    workout,
    stats,
    position,
    gpsWeak,
    accessIssue,
    showRationale,
    showBatteryTip,
    finishedWorkout,
    errorMessage,
  ];
}

const Object _keep = Object();
