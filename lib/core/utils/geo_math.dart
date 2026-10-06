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

  /// Initial bearing from [a] to [b] in degrees (0 = north, 90 = east).
  static double bearing(GeoPoint a, GeoPoint b) {
    final lat1 = _rad(a.lat);
    final lat2 = _rad(b.lat);
    final dLng = _rad(b.lng - a.lng);
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Smallest difference between two bearings, between 0 and 180 degrees.
  static double angleBetween(double bearingA, double bearingB) {
    final diff = (bearingA - bearingB).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }

  static double _rad(double degrees) => degrees * math.pi / 180;
}
