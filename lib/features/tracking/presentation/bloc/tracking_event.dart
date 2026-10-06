part of 'tracking_bloc.dart';

/// Inputs of [TrackingBloc].
sealed class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

/// Restores an unfinished workout after the app was killed.
final class TrackingRecoveryRequested extends TrackingEvent {
  const TrackingRecoveryRequested();
}

final class TrackingActivitySelected extends TrackingEvent {
  const TrackingActivitySelected(this.activity);

  final ActivityType activity;

  @override
  List<Object?> get props => [activity];
}

/// Start recording. If location is not granted yet, the state asks the UI
/// to explain why it is needed first ([TrackingState.showRationale]).
final class TrackingStartRequested extends TrackingEvent {
  const TrackingStartRequested();
}

/// The user read the explanation and agreed to grant location access.
final class TrackingRationaleAccepted extends TrackingEvent {
  const TrackingRationaleAccepted();
}

/// The user closed the explanation without granting access.
final class TrackingRationaleDismissed extends TrackingEvent {
  const TrackingRationaleDismissed();
}

/// Opens the system screen that fixes [TrackingState.accessIssue].
final class TrackingSettingsRequested extends TrackingEvent {
  const TrackingSettingsRequested();
}

/// Ask Android to stop optimizing (killing) the app in the background.
final class TrackingBatteryExemptionRequested extends TrackingEvent {
  const TrackingBatteryExemptionRequested();
}

final class TrackingBatteryTipDismissed extends TrackingEvent {
  const TrackingBatteryTipDismissed();
}

final class TrackingPauseRequested extends TrackingEvent {
  const TrackingPauseRequested();
}

final class TrackingResumeRequested extends TrackingEvent {
  const TrackingResumeRequested();
}

/// Finish and save the workout.
final class TrackingStopRequested extends TrackingEvent {
  const TrackingStopRequested();
}

/// Throw the current workout away.
final class TrackingDiscardRequested extends TrackingEvent {
  const TrackingDiscardRequested();
}

/// The summary was closed: go back to idle.
final class TrackingSummaryDismissed extends TrackingEvent {
  const TrackingSummaryDismissed();
}

final class _TrackingFixReceived extends TrackingEvent {
  const _TrackingFixReceived(this.fix);

  final LocationFix fix;

  @override
  List<Object?> get props => [fix];
}

final class _TrackingTicked extends TrackingEvent {
  const _TrackingTicked();
}

/// The location stream failed (permission revoked, GPS turned off...).
final class _TrackingLocationLost extends TrackingEvent {
  const _TrackingLocationLost();
}
