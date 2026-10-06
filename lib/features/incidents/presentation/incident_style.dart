import 'package:flutter/material.dart';

import '../domain/entities/incident.dart';

/// Color and icon of each [IncidentCategory], shared by markers, chips and
/// the report form.
extension IncidentCategoryStyle on IncidentCategory {
  Color get color => switch (this) {
    IncidentCategory.closedStreet => const Color(0xFFE53935),
    IncidentCategory.darkArea => const Color(0xFF5E35B1),
    IncidentCategory.noSidewalk => const Color(0xFFFB8C00),
    IncidentCategory.pothole => const Color(0xFF8D6E63),
    IncidentCategory.dangerousCrossing => const Color(0xFFD81B60),
    IncidentCategory.other => const Color(0xFF546E7A),
  };

  IconData get icon => switch (this) {
    IncidentCategory.closedStreet => Icons.block_rounded,
    IncidentCategory.darkArea => Icons.nights_stay_rounded,
    IncidentCategory.noSidewalk => Icons.directions_walk_rounded,
    IncidentCategory.pothole => Icons.warning_rounded,
    IncidentCategory.dangerousCrossing => Icons.traffic_rounded,
    IncidentCategory.other => Icons.report_rounded,
  };
}

/// Visual weight of each [IncidentSeverity].
extension IncidentSeverityStyle on IncidentSeverity {
  Color color(ColorScheme scheme) => switch (this) {
    IncidentSeverity.low => scheme.outline,
    IncidentSeverity.medium => const Color(0xFFF59E0B),
    IncidentSeverity.high => scheme.error,
  };
}
