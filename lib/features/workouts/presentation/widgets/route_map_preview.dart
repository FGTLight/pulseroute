import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/theme/map_styles.dart';
import '../../../map/presentation/widgets/map_converters.dart';

/// Non-interactive map that fits a whole route, for summaries and history.
class RouteMapPreview extends StatelessWidget {
  const RouteMapPreview({required this.route, super.key});

  final List<GeoPoint> route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bounds = boundsOf(route);
    final points = [for (final p in route) p.toLatLng()];

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: points.isEmpty ? defaultMapCenter : points.first,
        zoom: 14,
      ),
      style: MapStyles.forBrightness(Theme.of(context).brightness),
      liteModeEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) {
        if (bounds != null) {
          unawaited(
            controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, 32)),
          );
        }
      },
      polylines: {
        if (points.length > 1)
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: scheme.primary,
            width: 5,
          ),
      },
      markers: {
        if (points.isNotEmpty)
          Marker(
            markerId: const MarkerId('start'),
            position: points.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        if (points.length > 1)
          Marker(markerId: const MarkerId('end'), position: points.last),
      },
    );
  }
}
