import '../../../../core/domain/activity_type.dart';
import '../entities/track_point.dart';

/// What the app is allowed to do with the user's location.
enum LocationAccess {
  /// "While using the app": enough, since tracking runs in a foreground
  /// service that keeps working with the screen off.
  whileInUse,

  /// "Allow all the time".
  always,

  /// Denied, but the app may ask again.
  denied,

  /// Denied permanently: only the system settings can change it.
  deniedForever,

  /// Location services (GPS) are turned off.
  serviceDisabled;

  bool get isGranted => this == whileInUse || this == always;
}

/// Access to the device location and related system settings.
abstract interface class LocationRepository {
  Future<LocationAccess> checkAccess();

  /// Asks for location (and notification, for the tracking notification)
  /// permissions. Only call after explaining why they are needed.
  Future<LocationAccess> requestAccess();

  /// Continuous high-accuracy fixes. On Android this starts a foreground
  /// service with a persistent notification, so tracking continues with
  /// the screen off. Cancel the subscription to stop it.
  Stream<LocationFix> watch(ActivityType activity);

  /// Whether Android battery optimization may stop background tracking.
  Future<bool> isBatteryOptimized();

  /// Asks the user to exempt the app from battery optimization.
  Future<void> requestBatteryExemption();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}
