import '../../../../core/domain/geo_point.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/incident.dart';
import '../entities/incident_draft.dart';
import '../repositories/incident_repository.dart';

/// Loads the incidents around a point.
class GetNearbyIncidents {
  const GetNearbyIncidents(this._repository);

  final IncidentRepository _repository;

  /// Default search radius around the user.
  static const defaultRadiusM = 3000.0;

  Future<Result<List<Incident>>> call(
    GeoPoint center, {
    double radiusM = defaultRadiusM,
  }) => _repository.nearby(center, radiusM: radiusM);
}

/// Validates and stores a new report.
class ReportIncident {
  const ReportIncident(this._repository);

  final IncidentRepository _repository;

  Future<Result<Incident>> call(IncidentDraft draft) async {
    final error = draft.validate();
    if (error != null) return Err(ServerFailure(error));
    return await _repository.report(draft);
  }
}

/// Confirms or marks an incident as resolved.
class VoteOnIncident {
  const VoteOnIncident(this._repository);

  final IncidentRepository _repository;

  /// Reporters cannot confirm their own incident (enforced by RLS too), but
  /// they can mark it resolved.
  Future<Result<void>> call(Incident incident, IncidentVote vote) async {
    if (vote == IncidentVote.confirm &&
        incident.isReportedBy(_repository.currentUserId)) {
      return const Err(ServerFailure('You cannot confirm your own report.'));
    }
    return await _repository.vote(incident.id, vote);
  }
}
