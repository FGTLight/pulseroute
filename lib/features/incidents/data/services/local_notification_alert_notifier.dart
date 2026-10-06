import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/repositories/alert_notifier.dart';
import '../../domain/services/proximity_alert_engine.dart';

/// [AlertNotifier] that shows a high-priority notification with a vibration
/// pattern (works with the screen off) plus haptic feedback when the app is
/// in the foreground.
class LocalNotificationAlertNotifier implements AlertNotifier {
  LocalNotificationAlertNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static final _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'safety_alerts',
      'Safety alerts',
      channelDescription: 'Warnings about incidents ahead on your route',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.navigation,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
    ),
    iOS: const DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested together with location (see
        // GeolocatorLocationRepository), not on first notification.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> notify(ProximityAlert alert) async {
    try {
      await HapticFeedback.heavyImpact();
      await _ensureInitialized();
      final incident = alert.incident;
      await _plugin.show(
        id: incident.id.hashCode,
        title: 'Heads up: ${incident.category.label.toLowerCase()} ahead',
        body: incident.description.isNotEmpty
            ? '${alert.distanceM.round()} m · ${incident.description}'
            : '${alert.distanceM.round()} m ahead on your route',
        notificationDetails: _details,
      );
    } on Object catch (error) {
      // An alert must never interrupt the recording.
      debugPrint('Could not show proximity alert: $error');
    }
  }
}
