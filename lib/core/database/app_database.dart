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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // SQLite ignores foreign keys (and cascades) unless enabled.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
