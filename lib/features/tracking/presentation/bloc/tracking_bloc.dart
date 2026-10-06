import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/domain/geo_point.dart';
import '../../../../core/utils/time.dart';
import '../../../workouts/domain/entities/workout.dart';
import '../../domain/entities/active_workout.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/entities/workout_stats.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/workout_recorder_repository.dart';
import '../../domain/services/gps_noise_filter.dart';
import '../../domain/services/stats_accumulator.dart';
import '../../domain/usecases/finish_workout.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

/// Records a workout: listens to GPS fixes, filters them, updates the live
/// stats and persists every accepted point immediately.
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc({
    required LocationRepository location,
    required WorkoutRecorderRepository recorder,
    required FinishWorkout finishWorkout,
    required String Function() newId,
    Clock clock = DateTime.now,
    Ticker ticker = const PeriodicTicker(),
  }) : _location = location,
       _recorder = recorder,
       _finishWorkout = finishWorkout,
       _newId = newId,
       _clock = clock,
       _ticker = ticker,
       super(const TrackingState()) {
    on<TrackingRecoveryRequested>(_onRecoveryRequested);
    on<TrackingActivitySelected>(_onActivitySelected);
    on<TrackingStartRequested>(_onStartRequested);
    on<TrackingRationaleAccepted>(_onRationaleAccepted);
    on<TrackingRationaleDismissed>(
      (event, emit) => emit(state.copyWith(showRationale: false)),
    );
    on<TrackingSettingsRequested>(_onSettingsRequested);
    on<TrackingBatteryExemptionRequested>(_onBatteryExemptionRequested);
    on<TrackingBatteryTipDismissed>(
      (event, emit) => emit(state.copyWith(showBatteryTip: false)),
    );
    on<TrackingPauseRequested>(_onPauseRequested);
    on<TrackingResumeRequested>(_onResumeRequested);
    on<TrackingStopRequested>(_onStopRequested);
    on<TrackingDiscardRequested>(_onDiscardRequested);
    on<TrackingSummaryDismissed>(_onSummaryDismissed);
    on<_TrackingFixReceived>(_onFixReceived);
    on<_TrackingTicked>(_onTicked);
    on<_TrackingLocationLost>(_onLocationLost);
  }

  final LocationRepository _location;
  final WorkoutRecorderRepository _recorder;
  final FinishWorkout _finishWorkout;
  final String Function() _newId;
  final Clock _clock;
  final Ticker _ticker;

  StatsAccumulator _stats = const StatsAccumulator();
  GpsNoiseFilter _filter = GpsNoiseFilter(activity: ActivityType.run);
  StreamSubscription<LocationFix>? _fixes;
  StreamSubscription<void>? _ticks;

  // Lifecycle ----------------------------------------------------------------

  Future<void> _onRecoveryRequested(
    TrackingRecoveryRequested event,
    Emitter<TrackingState> emit,
  ) async {
    if (await _location.isBatteryOptimized()) {
      emit(state.copyWith(showBatteryTip: true));
    }

    final result = await _recorder.loadActive();
    var workout = result.valueOrNull;
    if (workout == null || state.status != TrackingStatus.idle) return;

    _stats = StatsAccumulator.fromPoints(workout.points);
    _filter = GpsNoiseFilter(activity: workout.activity);

    if (workout.isRecording) {
      final access = await _location.checkAccess();
      if (access.isGranted) {
        // The app was killed while recording: keep the clock running but
        // start a new segment so no line is drawn across the gap.
        workout = workout.newSegment();
        await _recorder.saveState(workout);
        _listen(workout.activity);
        emit(_stateFor(workout, TrackingStatus.recording));
        return;
      }
      workout = workout.pause(_clock());
      await _recorder.saveState(workout);
      emit(
        _stateFor(workout, TrackingStatus.paused).copyWith(accessIssue: access),
      );
      return;
    }
    emit(_stateFor(workout, TrackingStatus.paused));
  }

  void _onActivitySelected(
    TrackingActivitySelected event,
    Emitter<TrackingState> emit,
  ) {
    if (state.status == TrackingStatus.idle) {
      emit(state.copyWith(activity: event.activity));
    }
  }

  Future<void> _onStartRequested(
    TrackingStartRequested event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.status != TrackingStatus.idle) return;
    emit(state.copyWith(status: TrackingStatus.starting, accessIssue: null));

    final access = await _location.checkAccess();
    if (access.isGranted) {
      await _begin(emit);
      return;
    }

    // Explain first; only ask the system once the user agrees. Blocked
    // states (GPS off, denied forever) can only be fixed in the settings.
    final askable = access == LocationAccess.denied;
    emit(
      state.copyWith(
        status: TrackingStatus.idle,
        showRationale: askable,
        accessIssue: askable ? null : access,
      ),
    );
  }

  Future<void> _onRationaleAccepted(
    TrackingRationaleAccepted event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.status != TrackingStatus.idle) return;
    emit(state.copyWith(status: TrackingStatus.starting, showRationale: false));
    final access = await _location.requestAccess();
    if (!access.isGranted) {
      emit(state.copyWith(status: TrackingStatus.idle, accessIssue: access));
      return;
    }
    await _begin(emit);
  }

  Future<void> _onSettingsRequested(
    TrackingSettingsRequested event,
    Emitter<TrackingState> emit,
  ) async {
    if (state.accessIssue == LocationAccess.serviceDisabled) {
      await _location.openLocationSettings();
    } else {
      await _location.openAppSettings();
    }
    // The user may have fixed it; clear the issue so it is re-checked.
    emit(state.copyWith(accessIssue: null));
  }

  Future<void> _onBatteryExemptionRequested(
    TrackingBatteryExemptionRequested event,
    Emitter<TrackingState> emit,
  ) async {
    await _location.requestBatteryExemption();
    emit(state.copyWith(showBatteryTip: await _location.isBatteryOptimized()));
  }

  /// Creates the workout and starts listening to the GPS.
  Future<void> _begin(Emitter<TrackingState> emit) async {
    final workout = ActiveWorkout.start(
      id: _newId(),
      activity: state.activity,
      now: _clock(),
    );
    final saved = await _recorder.saveState(workout);
    if (!saved.isSuccess) {
      emit(
        state.copyWith(
          status: TrackingStatus.idle,
          errorMessage: saved.failureOrNull!.message,
        ),
      );
      return;
    }

    _stats = const StatsAccumulator();
    _filter = GpsNoiseFilter(activity: workout.activity);
    _listen(workout.activity);
    emit(_stateFor(workout, TrackingStatus.recording));
  }

  Future<void> _onPauseRequested(
    TrackingPauseRequested event,
    Emitter<TrackingState> emit,
  ) async {
    final workout = state.workout;
    if (workout == null || state.status != TrackingStatus.recording) return;

    // Stopping the stream also stops the foreground service (saves battery).
    await _stopListening();
    final paused = (await _flush(workout)).pause(_clock());
    _filter.reset();
    emit(_stateFor(paused, TrackingStatus.paused));
    await _recorder.saveState(paused);
  }

  Future<void> _onResumeRequested(
    TrackingResumeRequested event,
    Emitter<TrackingState> emit,
  ) async {
    final workout = state.workout;
    if (workout == null || state.status != TrackingStatus.paused) return;

    var access = await _location.checkAccess();
    if (!access.isGranted) access = await _location.requestAccess();
    if (!access.isGranted) {
      emit(state.copyWith(accessIssue: access));
      return;
    }

    final resumed = workout.resume(_clock());
    _filter.reset();
    _listen(resumed.activity);
    emit(
      _stateFor(resumed, TrackingStatus.recording).copyWith(accessIssue: null),
    );
    await _recorder.saveState(resumed);
  }

  Future<void> _onStopRequested(
    TrackingStopRequested event,
    Emitter<TrackingState> emit,
  ) async {
    final workout = state.workout;
    if (workout == null || !state.isActive) return;

    await _stopListening();
    final complete = workout.isRecording ? await _flush(workout) : workout;
    emit(state.copyWith(status: TrackingStatus.saving, workout: complete));

    final result = await _finishWorkout(complete, _clock());
    result.fold(
      (finished) => emit(
        TrackingState(
          status: TrackingStatus.finished,
          activity: workout.activity,
          finishedWorkout: finished,
          position: state.position,
        ),
      ),
      (failure) => emit(
        state.copyWith(
          status: TrackingStatus.paused,
          workout: complete.pause(_clock()),
          errorMessage: failure.message,
        ),
      ),
    );
  }

  Future<void> _onDiscardRequested(
    TrackingDiscardRequested event,
    Emitter<TrackingState> emit,
  ) async {
    final workout = state.workout;
    if (workout == null) return;
    await _stopListening();
    await _recorder.discard(workout.id);
    emit(TrackingState(activity: state.activity, position: state.position));
  }

  void _onSummaryDismissed(
    TrackingSummaryDismissed event,
    Emitter<TrackingState> emit,
  ) {
    emit(TrackingState(activity: state.activity, position: state.position));
  }

  // GPS and clock ------------------------------------------------------------

  Future<void> _onFixReceived(
    _TrackingFixReceived event,
    Emitter<TrackingState> emit,
  ) async {
    final workout = state.workout;
    if (workout == null || state.status != TrackingStatus.recording) return;

    final result = _filter.process(event.fix, segment: workout.segment);
    if (result is! Accepted) {
      emit(
        state.copyWith(
          position: event.fix.point,
          gpsWeak:
              result is Rejected &&
              result.reason == RejectionReason.lowAccuracy,
        ),
      );
      return;
    }

    // Update the state synchronously (before any await) so concurrent fixes
    // never read a stale point list.
    final point = result.point;
    _stats = _stats.add(point);
    final updated = workout.addPoint(point);
    emit(
      _stateFor(
        updated,
        TrackingStatus.recording,
      ).copyWith(position: point.point, gpsWeak: false),
    );
    await _recorder.appendPoint(updated.id, point);
  }

  void _onTicked(_TrackingTicked event, Emitter<TrackingState> emit) {
    final workout = state.workout;
    if (workout == null || state.status != TrackingStatus.recording) return;
    emit(state.copyWith(stats: _stats.toStats(workout.elapsed(_clock()))));
  }

  Future<void> _onLocationLost(
    _TrackingLocationLost event,
    Emitter<TrackingState> emit,
  ) async {
    final workout = state.workout;
    if (workout == null || state.status != TrackingStatus.recording) return;

    await _stopListening();
    final paused = (await _flush(workout)).pause(_clock());
    final access = await _location.checkAccess();
    emit(
      _stateFor(paused, TrackingStatus.paused).copyWith(
        // A failing stream with access still granted means GPS went off.
        accessIssue: access.isGranted ? LocationAccess.serviceDisabled : access,
      ),
    );
    await _recorder.saveState(paused);
  }

  // Helpers ------------------------------------------------------------------

  TrackingState _stateFor(ActiveWorkout workout, TrackingStatus status) =>
      state.copyWith(
        status: status,
        activity: workout.activity,
        workout: workout,
        stats: _stats.toStats(workout.elapsed(_clock())),
        position: workout.points.isEmpty ? null : workout.points.last.point,
      );

  /// Adds the filter's trailing raw fix so a segment ends where the user
  /// actually stopped.
  Future<ActiveWorkout> _flush(ActiveWorkout workout) async {
    final point = _filter.flush(segment: workout.segment);
    if (point == null) return workout;
    _stats = _stats.add(point);
    await _recorder.appendPoint(workout.id, point);
    return workout.addPoint(point);
  }

  void _listen(ActivityType activity) {
    unawaited(_fixes?.cancel());
    unawaited(_ticks?.cancel());
    _fixes = _location
        .watch(activity)
        .listen(
          (fix) => add(_TrackingFixReceived(fix)),
          onError: (Object _) => add(const _TrackingLocationLost()),
        );
    _ticks = _ticker
        .tick(const Duration(seconds: 1))
        .listen((_) => add(const _TrackingTicked()));
  }

  Future<void> _stopListening() async {
    await _fixes?.cancel();
    await _ticks?.cancel();
    _fixes = null;
    _ticks = null;
  }

  @override
  Future<void> close() async {
    await _stopListening();
    await super.close();
  }
}
