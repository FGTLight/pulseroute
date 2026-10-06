import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/time.dart';
import '../../../settings/domain/settings_repository.dart';
import '../../../tracking/domain/entities/track_point.dart';
import '../../../tracking/presentation/bloc/tracking_bloc.dart';
import '../../domain/entities/incident.dart';
import '../../domain/repositories/alert_notifier.dart';
import '../../domain/services/proximity_alert_engine.dart';

/// Proximity alerts of the current workout.
final class ProximityAlertState extends Equatable {
  const ProximityAlertState({
    this.workoutId,
    this.alerted = const {},
    this.latest,
  });

  /// Workout the [alerted] ids belong to.
  final String? workoutId;

  /// Incidents already alerted during this workout (never repeated).
  final Set<String> alerted;

  /// Most recent alert, shown as a banner until dismissed.
  final ProximityAlert? latest;

  @override
  List<Object?> get props => [workoutId, alerted, latest];
}

/// Watches the recording and warns once per incident that lies ahead on
/// the user's path.
///
/// It listens to the tracking bloc's *stream* (not to widgets), so alerts
/// keep firing while the screen is off and the foreground service runs.
class ProximityAlertCubit extends Cubit<ProximityAlertState> {
  ProximityAlertCubit({
    required Stream<TrackingState> tracking,
    required List<Incident> Function() incidents,
    required AlertNotifier notifier,
    required SettingsRepository settings,
    ProximityAlertEngine engine = const ProximityAlertEngine(),
    Clock clock = DateTime.now,
  }) : _incidents = incidents,
       _notifier = notifier,
       _settings = settings,
       _engine = engine,
       _clock = clock,
       super(const ProximityAlertState()) {
    _subscription = tracking.listen(_onTracking);
  }

  final List<Incident> Function() _incidents;
  final AlertNotifier _notifier;
  final SettingsRepository _settings;
  final ProximityAlertEngine _engine;
  final Clock _clock;
  late final StreamSubscription<TrackingState> _subscription;
  TrackPoint? _lastPoint;

  Future<void> _onTracking(TrackingState tracking) async {
    final workout = tracking.workout;

    // A new workout starts with a clean slate.
    if (workout?.id != state.workoutId) {
      _lastPoint = null;
      emit(ProximityAlertState(workoutId: workout?.id));
    }
    if (workout == null || tracking.status != TrackingStatus.recording) return;

    // Only evaluate when a new point was recorded.
    final points = workout.points;
    if (points.isEmpty || points.last == _lastPoint) return;
    _lastPoint = points.last;
    if (!_settings.alertsEnabled) return;

    final alert = _engine
        .copyWith(radiusM: _settings.alertRadiusM.toDouble())
        .check(
          route: points,
          incidents: _incidents(),
          alreadyAlerted: state.alerted,
          now: _clock(),
        );
    if (alert == null) return;

    emit(
      ProximityAlertState(
        workoutId: state.workoutId,
        alerted: {...state.alerted, alert.incident.id},
        latest: alert,
      ),
    );
    await _notifier.notify(alert);
  }

  /// Hides the in-app banner (the incident still will not alert again).
  void dismiss() => emit(
    ProximityAlertState(workoutId: state.workoutId, alerted: state.alerted),
  );

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
