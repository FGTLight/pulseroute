import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/theme/map_styles.dart';
import '../../../map/presentation/widgets/incident_layer.dart';
import '../../../map/presentation/widgets/map_converters.dart';

/// Full-screen map with the live route. Follows the user until they pan
/// the map; [RecenterButton] resumes following.
class TrackingMap extends StatefulWidget {
  const TrackingMap({
    required this.segments,
    required this.position,
    required this.showMyLocation,
    this.bottomPadding = 0,
    this.incidents,
    this.onLongPress,
    super.key,
  });

  /// Route split by pauses.
  final List<List<GeoPoint>> segments;
  final GeoPoint? position;
  final bool showMyLocation;

  /// Space covered by the stats panel, so Google's logo stays visible.
  final double bottomPadding;

  /// Community incidents drawn on top of the route.
  final IncidentLayer? incidents;

  /// Long-press on the map (used to report an incident there).
  final ValueChanged<GeoPoint>? onLongPress;

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap> {
  GoogleMapController? _controller;
  bool _follow = true;

  @override
  void didUpdateWidget(TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final position = widget.position;
    if (_follow && position != null && position != oldWidget.position) {
      unawaited(
        _controller?.animateCamera(CameraUpdate.newLatLng(position.toLatLng())),
      );
    }
  }

  void _recenter() {
    setState(() => _follow = true);
    final position = widget.position;
    if (position != null) {
      unawaited(
        _controller?.animateCamera(
          CameraUpdate.newLatLngZoom(position.toLatLng(), 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = widget.position?.toLatLng() ?? defaultMapCenter;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: start,
            zoom: widget.position == null ? 13 : 16,
          ),
          style: MapStyles.forBrightness(Theme.of(context).brightness),
          myLocationEnabled: widget.showMyLocation,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          padding: EdgeInsets.only(bottom: widget.bottomPadding),
          onMapCreated: (c) => _controller = c,
          // Panning by hand stops following the user.
          onCameraMoveStarted: () {
            if (_follow) setState(() => _follow = false);
          },
          onLongPress: widget.onLongPress == null
              ? null
              : (p) => widget.onLongPress!(GeoPoint(p.latitude, p.longitude)),
          markers: widget.incidents?.markers ?? const {},
          circles: widget.incidents?.circles ?? const {},
          clusterManagers: IncidentLayer.clusterManagers,
          polylines: {
            for (var i = 0; i < widget.segments.length; i++)
              Polyline(
                polylineId: PolylineId('segment-$i'),
                points: [for (final p in widget.segments[i]) p.toLatLng()],
                color: scheme.primary,
                width: 6,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
          },
        ),
        if (!_follow)
          Positioned(
            right: 16,
            bottom: widget.bottomPadding + 16,
            child: RecenterButton(onPressed: _recenter),
          ),
      ],
    );
  }
}

/// Small button that centers the map on the user again.
class RecenterButton extends StatelessWidget {
  const RecenterButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'recenter',
      tooltip: 'Center on my position',
      onPressed: onPressed,
      child: const Icon(Icons.my_location_rounded),
    );
  }
}
