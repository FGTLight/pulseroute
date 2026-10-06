import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/incident_style.dart';
import 'incident_marker_icons.dart';
import 'map_converters.dart';

/// Map objects (markers, area circles, clustering) for a list of incidents,
/// shared by the tracking map and the incidents map.
class IncidentLayer {
  IncidentLayer({
    required List<Incident> incidents,
    required IncidentMarkerIcons? icons,
    required ValueChanged<Incident> onTap,
  }) : markers = {
         for (final i in incidents)
           Marker(
             markerId: MarkerId(i.id),
             position: i.location.toLatLng(),
             icon: icons?[i.category] ?? BitmapDescriptor.defaultMarker,
             anchor: const Offset(0.5, 0.5),
             // Nearby markers merge into a numbered cluster when zoomed out.
             clusterManagerId: clusterId,
             onTap: () => onTap(i),
           ),
       },
       circles = {
         for (final i in incidents.where((i) => i.isArea))
           Circle(
             circleId: CircleId(i.id),
             center: i.location.toLatLng(),
             radius: i.radiusM!.toDouble(),
             fillColor: i.category.color.withValues(alpha: .18),
             strokeColor: i.category.color.withValues(alpha: .6),
             strokeWidth: 2,
             consumeTapEvents: true,
             onTap: () => onTap(i),
           ),
       };

  /// An empty layer.
  IncidentLayer.empty() : markers = const {}, circles = const {};

  static const clusterId = ClusterManagerId('incidents');

  /// Cluster manager referenced by every marker.
  static final Set<ClusterManager> clusterManagers = {
    const ClusterManager(clusterManagerId: clusterId),
  };

  final Set<Marker> markers;
  final Set<Circle> circles;
}
