import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/domain/geo_point.dart';

/// Conversions between the domain [GeoPoint] and the Google Maps types, kept
/// in the `map` feature so the rest of the app never imports the maps SDK.
extension GeoPointMaps on GeoPoint {
  LatLng toLatLng() => LatLng(lat, lng);
}

/// Bounds that contain every point, or `null` for an empty list.
LatLngBounds? boundsOf(Iterable<GeoPoint> points) {
  if (points.isEmpty) return null;
  var south = 90.0;
  var north = -90.0;
  var west = 180.0;
  var east = -180.0;
  for (final p in points) {
    if (p.lat < south) south = p.lat;
    if (p.lat > north) north = p.lat;
    if (p.lng < west) west = p.lng;
    if (p.lng > east) east = p.lng;
  }
  return LatLngBounds(
    southwest: LatLng(south, west),
    northeast: LatLng(north, east),
  );
}

/// Default camera target when the position is unknown: Porto Alegre, the
/// demo city of the seed data.
const defaultMapCenter = LatLng(-30.0346, -51.2177);
