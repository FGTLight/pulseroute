import 'dart:math' as math;

import '../domain/geo_point.dart';

/// Geodesic helpers on a spherical Earth, accurate enough for workout
/// tracking (error well under 0.5% at these distances).
abstract final class GeoMath {
  /// Mean Earth radius in meters.
  static const earthRadiusM = 6371008.8;

  /// Great-circle distance in meters (haversine formula).
  static double distance(GeoPoint a, GeoPoint b) {
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.lat)) *
            math.cos(_rad(b.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Shortest distance in meters from [p] to the segment [a]–[b], using a
  /// local equirectangular projection (fine for segments of a few km).
  static double distanceToSegment(GeoPoint p, GeoPoint a, GeoPoint b) {
    final cosLat = math.cos(_rad(p.lat));
    double x(GeoPoint g) => _rad(g.lng - p.lng) * cosLat * earthRadiusM;
    double y(GeoPoint g) => _rad(g.lat - p.lat) * earthRadiusM;

    final ax = x(a);
    final ay = y(a);
    final bx = x(b);
    final by = y(b);
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSq = dx * dx + dy * dy;
    final t = lengthSq == 0
        ? 0.0
        : ((-ax * dx - ay * dy) / lengthSq).clamp(0.0, 1.0);
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    return math.sqrt(cx * cx + cy * cy);
  }

  static double _rad(double degrees) => degrees * math.pi / 180;
}
