import 'package:drift/drift.dart';

/// Workouts stored on the device: in progress, or finished and maybe not
/// uploaded yet.
@DataClassName('LocalWorkoutRow')
class LocalWorkouts extends Table {
  @override
  String get tableName => 'workouts';

  /// UUID generated on the device, reused as the server id.
  TextColumn get id => text()();
  TextColumn get activity => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// `recording`, `paused` or `finished`.
  TextColumn get status => text()();
  IntColumn get activeDurationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get resumedAt => dateTime().nullable()();
  IntColumn get segment => integer().withDefault(const Constant(0))();

  // Final numbers, filled in when the workout finishes.
  RealColumn get distanceM => real().withDefault(const Constant(0))();
  RealColumn get elevationGainM => real().withDefault(const Constant(0))();
  RealColumn get maxSpeedMps => real().withDefault(const Constant(0))();

  /// JSON list of split durations in milliseconds.
  TextColumn get splitsJson => text().withDefault(const Constant('[]'))();

  /// Simplified route (`[[lat, lng], ...]`) for history thumbnails, so the
  /// list never loads thousands of points. Added in schema version 2.
  TextColumn get previewJson => text().withDefault(const Constant('[]'))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Accepted GPS points, written one by one while recording.
@DataClassName('LocalTrackPointRow')
@TableIndex(name: 'track_points_workout_idx', columns: {#workoutId})
class LocalTrackPoints extends Table {
  @override
  String get tableName => 'track_points';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get workoutId =>
      text().references(LocalWorkouts, #id, onDelete: KeyAction.cascade)();
  IntColumn get segment => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get accuracyM => real()();
  RealColumn get altitudeM => real().nullable()();
  RealColumn get speedMps => real().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
}
