import '../domain/geo_point.dart';

/// Builds Extended WKT strings that PostGIS parses into geography values.
/// Note PostGIS uses (longitude latitude) order.
abstract final class Ewkt {
  static String point(GeoPoint p) => 'SRID=4326;POINT(${p.lng} ${p.lat})';

  /// `SRID=4326;LINESTRING(lng lat, ...)`, or `null` with fewer than two
  /// points (PostGIS rejects such lines).
  static String? lineString(List<GeoPoint> route) {
    if (route.length < 2) return null;
    final coords = route
        .map((p) => '${p.lng.toStringAsFixed(6)} ${p.lat.toStringAsFixed(6)}')
        .join(',');
    return 'SRID=4326;LINESTRING($coords)';
  }
}
