import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/tracking/data/local/tracking_tables.dart';

part 'app_database.g.dart';

/// The on-device SQLite database. Feature tables live in their features;
/// this class wires them together and owns the migrations.
@DriftDatabase(tables: [LocalWorkouts, LocalTrackPoints])
class AppDatabase extends _$AppDatabase {
  /// Opens the device database, or uses [executor] (in-memory in tests).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'pulseroute'));

  @override
  int get schemaVersion => 2;

  /// Removes every workout and point (used after deleting the account).
  Future<void> clearAll() => transaction(() async {
    await delete(localTrackPoints).go();
    await delete(localWorkouts).go();
  });

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: route previews for the history list. Older workouts get their
      // preview computed on first read (see DriftWorkoutRepository).
      if (from < 2) {
        await m.addColumn(localWorkouts, localWorkouts.previewJson);
      }
    },
    beforeOpen: (details) async {
      // SQLite ignores foreign keys (and cascades) unless enabled.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
