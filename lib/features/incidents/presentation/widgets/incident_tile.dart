import 'package:flutter/material.dart';

import '../../../../core/domain/distance_unit.dart';
import '../../../../core/domain/geo_point.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo_math.dart';
import '../../domain/entities/incident.dart';
import '../incident_style.dart';

/// A row in the incidents list.
class IncidentTile extends StatelessWidget {
  const IncidentTile({
    required this.incident,
    required this.onTap,
    this.from,
    super.key,
  });

  final Incident incident;
  final GeoPoint? from;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final origin = from;
    final details = [
      Formatters.age(incident.createdAt, DateTime.now()),
      if (origin != null)
        Formatters.shortDistance(
          GeoMath.distance(origin, incident.location),
          DistanceUnit.km,
        ),
      if (incident.confirmations > 0) '${incident.confirmations} confirmed',
    ].join(' · ');

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: incident.category.color,
          child: Icon(incident.category.icon, color: Colors.white, size: 20),
        ),
        title: Text(incident.category.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incident.description.isNotEmpty)
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(details, style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: Icon(
          Icons.circle,
          size: 12,
          color: incident.severity.color(theme.colorScheme),
          semanticLabel: '${incident.severity.label} severity',
        ),
      ),
    );
  }
}
