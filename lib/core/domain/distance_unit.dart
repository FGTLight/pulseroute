/// Units used to display distances, paces and speeds.
enum DistanceUnit {
  km('km', 1000),
  mi('mi', 1609.344);

  const DistanceUnit(this.label, this.meters);

  final String label;

  /// Meters in one unit.
  final double meters;
}
