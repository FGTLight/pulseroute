import '../../../../core/domain/geo_point.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_draft.dart';

/// Maps rows of `incidents` (from RPCs, inserts and Realtime payloads).
abstract final class IncidentModel {
  /// `IncidentCategory.closedStreet` ↔ `'closed_street'`.
  static String categoryToDb(IncidentCategory c) => c.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '_${m[0]!.toLowerCase()}',
  );

  static IncidentCategory categoryFromDb(String? value) =>
      IncidentCategory.values.firstWhere(
        (c) => categoryToDb(c) == value,
        orElse: () => IncidentCategory.other,
      );

  /// [photoUrlFor] turns a storage path into a public URL.
  static Incident fromJson(
    Map<String, dynamic> json, {
    required String Function(String path) photoUrlFor,
    IncidentVote? myVote,
  }) {
    final photoPath = json['photo_path'] as String?;
    return Incident(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String?,
      category: categoryFromDb(json['category'] as String?),
      severity: IncidentSeverity.fromLevel((json['severity'] as num?)?.toInt()),
      description: json['description'] as String? ?? '',
      location: GeoPoint(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      radiusM: (json['radius_m'] as num?)?.toInt(),
      photoUrl: photoPath == null || photoPath.isEmpty
          ? null
          : photoUrlFor(photoPath),
      status: json['status'] == 'resolved'
          ? IncidentStatus.resolved
          : IncidentStatus.active,
      confirmations: (json['confirmations'] as num?)?.toInt() ?? 0,
      resolutions: (json['resolutions'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      myVote: myVote,
    );
  }

  /// Row inserted for a new report. The point is sent as EWKT; PostGIS
  /// fills the generated `lat` / `lng` columns.
  static Map<String, dynamic> toInsertJson(
    IncidentDraft draft, {
    String? photoPath,
  }) => {
    'category': categoryToDb(draft.category),
    'severity': draft.severity.level,
    'description': draft.description.trim(),
    'location': 'SRID=4326;POINT(${draft.location.lng} ${draft.location.lat})',
    'radius_m': draft.radiusM,
    'photo_path': photoPath,
  };

  static IncidentVote? voteFromDb(String? value) =>
      IncidentVote.values.where((v) => v.name == value).firstOrNull;
}
