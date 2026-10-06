import '../../../../core/domain/geo_point.dart';

/// Reduces a route to at most [maxPoints] by keeping evenly spaced points
/// (always including the first and last). Good enough for thumbnails, where
/// exact shape matters less than size.
List<GeoPoint> simplifyRoute(List<GeoPoint> route, {int maxPoints = 60}) {
  if (route.length <= maxPoints) return List.of(route);
  final step = (route.length - 1) / (maxPoints - 1);
  return [for (var i = 0; i < maxPoints; i++) route[(i * step).round()]];
}
