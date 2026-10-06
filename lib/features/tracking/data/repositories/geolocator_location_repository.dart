import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/domain/activity_type.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/location_repository.dart';

/// [LocationRepository] using `geolocator` (fixes and the Android
/// foreground service) and `permission_handler` (notifications, battery).
class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository();

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<LocationAccess> checkAccess() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    return _map(await geo.Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> requestAccess() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }
    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    final access = _map(permission);
    if (access.isGranted && _isAndroid) {
      // Android 13+: without it the tracking notification is hidden
      // (tracking still works). The result is intentionally ignored.
      await Permission.notification.request();
    }
    return access;
  }

  @override
  Stream<LocationFix> watch(ActivityType activity) {
    return geo.Geolocator.getPositionStream(
      locationSettings: _settingsFor(activity),
    ).map(
      (p) => LocationFix(
        lat: p.latitude,
        lng: p.longitude,
        accuracyM: p.accuracy,
        timestamp: p.timestamp,
        altitudeM: p.hasAltitude ? p.altitude : null,
        speedMps: p.hasSpeed && p.speed >= 0 ? p.speed : null,
      ),
    );
  }

  geo.LocationSettings _settingsFor(ActivityType activity) {
    final what = activity == ActivityType.run ? 'run' : 'ride';
    // distanceFilter keeps its default (0): every fix is delivered and the
    // GPS noise filter decides what to keep. iOS also keeps updating in the
    // background by default (pauseLocationUpdatesAutomatically is false).
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        intervalDuration: const Duration(seconds: 2),
        // Runs a foreground service so tracking survives the screen being off.
        foregroundNotificationConfig: geo.ForegroundNotificationConfig(
          notificationTitle: 'Recording your $what',
          notificationText: 'PulseRoute keeps tracking with the screen off.',
          notificationChannelName: 'Workout tracking',
          enableWakeLock: true,
          setOngoing: true,
        ),
      ),
      TargetPlatform.iOS => geo.AppleSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        activityType: geo.ActivityType.fitness,
        showBackgroundLocationIndicator: true,
      ),
      _ => const geo.LocationSettings(),
    };
  }

  @override
  Future<bool> isBatteryOptimized() async {
    if (!_isAndroid) return false;
    return !await Permission.ignoreBatteryOptimizations.isGranted;
  }

  @override
  Future<void> requestBatteryExemption() async {
    if (_isAndroid) await Permission.ignoreBatteryOptimizations.request();
  }

  @override
  Future<void> openAppSettings() => geo.Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => geo.Geolocator.openLocationSettings();

  static LocationAccess _map(geo.LocationPermission permission) =>
      switch (permission) {
        geo.LocationPermission.always => LocationAccess.always,
        geo.LocationPermission.whileInUse => LocationAccess.whileInUse,
        geo.LocationPermission.deniedForever => LocationAccess.deniedForever,
        geo.LocationPermission.denied ||
        geo.LocationPermission.unableToDetermine => LocationAccess.denied,
      };
}
