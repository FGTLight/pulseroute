/// Kind of workout. The [name] matches the `activity_type` enum in Postgres.
enum ActivityType {
  run('Run'),
  bike('Ride');

  const ActivityType(this.label);

  /// Human readable name.
  final String label;

  /// Parses the database value, defaulting to [run].
  static ActivityType fromName(String? name) =>
      values.firstWhere((a) => a.name == name, orElse: () => run);
}
