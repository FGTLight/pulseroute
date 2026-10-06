import '../services/proximity_alert_engine.dart';

/// Delivers a proximity alert to the user (notification + vibration), also
/// while the screen is off.
abstract interface class AlertNotifier {
  Future<void> notify(ProximityAlert alert);
}
