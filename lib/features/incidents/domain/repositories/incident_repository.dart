import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/errors/result.dart';
import '../entities/incident.dart';
import '../entities/incident_draft.dart';

/// A live change pushed by the server.
sealed class IncidentChange extends Equatable {
  const IncidentChange();
}

/// An incident was created or updated (votes, status...).
final class IncidentUpserted extends IncidentChange {
  const IncidentUpserted(this.incident);

  final Incident incident;

  @override
  List<Object?> get props => [incident];
}

/// An incident was deleted by its reporter.
final class IncidentRemoved extends IncidentChange {
  const IncidentRemoved(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Community incidents stored in the backend.
abstract interface class IncidentRepository {
  /// Live incidents within [radiusM] of [center], with the user's own votes.
  Future<Result<List<Incident>>> nearby(GeoPoint center, {double radiusM});

  /// Pushes inserts, updates and deletes as they happen (Realtime).
  Stream<IncidentChange> watchChanges();

  /// Stores a new report; the photo is uploaded first.
  Future<Result<Incident>> report(IncidentDraft draft);

  Future<Result<void>> vote(String incidentId, IncidentVote vote);

  /// Incidents within [bufferM] of a workout route. Uploaded workouts
  /// ([synced]) also include incidents resolved since the workout.
  Future<Result<List<Incident>>> nearRoute({
    required String workoutId,
    required List<GeoPoint> route,
    required bool synced,
    double bufferM = 50,
  });

  /// Id of the signed-in user, to tell their own reports apart.
  String? get currentUserId;
}

/// Picks and compresses a photo for a report.
abstract interface class PhotoRepository {
  /// Returns `null` if the user cancels.
  Future<Result<Uint8List?>> pick({required bool fromCamera});
}
