import 'package:equatable/equatable.dart';

import '../../../../core/domain/geo_point.dart';

/// Kind of hazard. The [name] matches the `incident_category` Postgres enum
/// (converted to snake_case by the model).
enum IncidentCategory {
  closedStreet('Closed street', defaultRadiusM: null),
  darkArea('Dark area', defaultRadiusM: 150),
  noSidewalk('No sidewalk', defaultRadiusM: null),
  pothole('Pothole / damaged road', defaultRadiusM: null),
  dangerousCrossing('Dangerous crossing', defaultRadiusM: null),
  other('Other', defaultRadiusM: null);

  const IncidentCategory(this.label, {required this.defaultRadiusM});

  final String label;

  /// Area-type categories are reported as a circle by default.
  final int? defaultRadiusM;
}

/// How dangerous the incident is.
enum IncidentSeverity {
  low('Low'),
  medium('Medium'),
  high('High');

  const IncidentSeverity(this.label);

  final String label;

  /// Value stored in the database (1–3).
  int get level => index + 1;

  static IncidentSeverity fromLevel(int? level) =>
      values[((level ?? 2) - 1).clamp(0, values.length - 1)];
}

enum IncidentStatus { active, resolved }

/// A community vote on an incident.
enum IncidentVote { confirm, resolve }

/// A community-reported urban hazard.
class Incident extends Equatable {
  const Incident({
    required this.id,
    required this.category,
    required this.severity,
    required this.location,
    required this.createdAt,
    required this.expiresAt,
    this.reporterId,
    this.description = '',
    this.radiusM,
    this.photoUrl,
    this.status = IncidentStatus.active,
    this.confirmations = 0,
    this.resolutions = 0,
    this.myVote,
  });

  final String id;
  final String? reporterId;
  final IncidentCategory category;
  final IncidentSeverity severity;
  final String description;
  final GeoPoint location;

  /// Set for area reports (drawn as a circle).
  final int? radiusM;
  final String? photoUrl;
  final IncidentStatus status;
  final int confirmations;
  final int resolutions;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// The signed-in user's vote, if any.
  final IncidentVote? myVote;

  bool get isArea => radiusM != null;

  /// Whether it should still be shown and alerted on.
  bool isLive(DateTime now) =>
      status == IncidentStatus.active && expiresAt.isAfter(now);

  bool isReportedBy(String? userId) => userId != null && reporterId == userId;

  Incident copyWith({
    int? confirmations,
    int? resolutions,
    IncidentStatus? status,
    Object? myVote = _keep,
  }) {
    return Incident(
      id: id,
      reporterId: reporterId,
      category: category,
      severity: severity,
      description: description,
      location: location,
      radiusM: radiusM,
      photoUrl: photoUrl,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
      confirmations: confirmations ?? this.confirmations,
      resolutions: resolutions ?? this.resolutions,
      myVote: identical(myVote, _keep) ? this.myVote : myVote as IncidentVote?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    reporterId,
    category,
    severity,
    description,
    location,
    radiusM,
    photoUrl,
    status,
    confirmations,
    resolutions,
    createdAt,
    expiresAt,
    myVote,
  ];
}

const Object _keep = Object();
