import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident.dart';

final incidentNow = DateTime(2026, 10, 6, 12);

/// Origin used by incident tests (Porto Alegre waterfront).
const origin = GeoPoint(-30.0391, -51.2405);

/// An active incident [metersNorth] north of [origin].
Incident incidentAt(
  String id, {
  double metersNorth = 0,
  IncidentCategory category = IncidentCategory.pothole,
  int confirmations = 0,
  IncidentVote? myVote,
  String? reporterId = 'someone-else',
  int? radiusM,
  IncidentStatus status = IncidentStatus.active,
  Duration age = const Duration(hours: 2),
}) => Incident(
  id: id,
  reporterId: reporterId,
  category: category,
  severity: IncidentSeverity.medium,
  description: 'Test $id',
  location: GeoPoint(origin.lat + metersNorth / 111195.08, origin.lng),
  radiusM: radiusM,
  status: status,
  confirmations: confirmations,
  createdAt: incidentNow.subtract(age),
  expiresAt: incidentNow.add(const Duration(days: 10)),
  myVote: myVote,
);
