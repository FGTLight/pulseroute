import '../domain/distance_unit.dart';

/// Human readable workout numbers. Pure functions, so they are unit tested.
abstract final class Formatters {
  /// Below this speed the user is considered stopped (no pace shown).
  static const minMovingSpeedMps = 0.5;

  /// "5.23 km" / "3.25 mi".
  static String distance(double meters, DistanceUnit unit) =>
      '${(meters / unit.meters).toStringAsFixed(2)} ${unit.label}';

  /// "12:34" or "1:02:03".
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  /// Time per unit, e.g. "5:12 /km". Shows "--:--" when not moving.
  static String pace(double speedMps, DistanceUnit unit) {
    if (speedMps < minMovingSpeedMps) return '--:-- /${unit.label}';
    final seconds = (unit.meters / speedMps).round();
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s /${unit.label}';
  }

  /// "18.4 km/h" / "11.4 mph".
  static String speed(double speedMps, DistanceUnit unit) {
    final perHour = speedMps * 3600 / unit.meters;
    final label = unit == DistanceUnit.km ? 'km/h' : 'mph';
    return '${perHour.toStringAsFixed(1)} $label';
  }

  /// Elevation in meters or feet: "120 m" / "394 ft".
  static String elevation(double meters, DistanceUnit unit) =>
      unit == DistanceUnit.km
      ? '${meters.round()} m'
      : '${(meters * 3.28084).round()} ft';
}
