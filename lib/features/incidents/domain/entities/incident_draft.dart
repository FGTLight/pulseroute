import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/domain/geo_point.dart';
import 'incident.dart';

/// A new report, before it is stored.
class IncidentDraft extends Equatable {
  const IncidentDraft({
    required this.category,
    required this.severity,
    required this.location,
    this.description = '',
    this.radiusM,
    this.photo,
  });

  static const maxDescriptionLength = 280;
  static const minRadiusM = 25;
  static const maxRadiusM = 500;

  final IncidentCategory category;
  final IncidentSeverity severity;
  final GeoPoint location;
  final String description;
  final int? radiusM;

  /// Compressed JPEG bytes, if the user attached a photo.
  final Uint8List? photo;

  /// Error message, or `null` when the draft can be submitted.
  String? validate() {
    if (description.trim().length > maxDescriptionLength) {
      return 'Keep the description under $maxDescriptionLength characters';
    }
    final radius = radiusM;
    if (radius != null && (radius < minRadiusM || radius > maxRadiusM)) {
      return 'The area must be between $minRadiusM and $maxRadiusM m';
    }
    return null;
  }

  @override
  List<Object?> get props => [
    category,
    severity,
    location,
    description,
    radiusM,
    photo?.length,
  ];
}
