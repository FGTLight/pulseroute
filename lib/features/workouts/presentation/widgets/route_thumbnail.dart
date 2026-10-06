import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/domain/geo_point.dart';

/// Lightweight drawing of a route (no map tiles), used for list thumbnails
/// where one native map per row would be too heavy.
class RouteThumbnail extends StatelessWidget {
  const RouteThumbnail({
    required this.route,
    this.size = 72,
    this.strokeWidth = 3,
    super.key,
  });

  final List<GeoPoint> route;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: CustomPaint(
        painter: RoutePainter(
          route: route,
          color: scheme.primary,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Paints [route] scaled to fit, keeping its aspect ratio.
class RoutePainter extends CustomPainter {
  RoutePainter({
    required this.route,
    required this.color,
    this.strokeWidth = 3,
    this.padding = 10,
  });

  final List<GeoPoint> route;
  final Color color;
  final double strokeWidth;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;

    // Equirectangular projection around the route center.
    final midLat =
        route.map((p) => p.lat).reduce((a, b) => a + b) / route.length;
    final cosLat = math.cos(midLat * math.pi / 180);
    final xs = [for (final p in route) p.lng * cosLat];
    final ys = [for (final p in route) -p.lat];
    final minX = xs.reduce(math.min);
    final minY = ys.reduce(math.min);
    final spanX = xs.reduce(math.max) - minX;
    final spanY = ys.reduce(math.max) - minY;
    final span = math.max(spanX, spanY);
    if (span == 0) return;

    final scale = (math.min(size.width, size.height) - 2 * padding) / span;
    final dx = (size.width - spanX * scale) / 2;
    final dy = (size.height - spanY * scale) / 2;
    Offset at(int i) =>
        Offset(dx + (xs[i] - minX) * scale, dy + (ys[i] - minY) * scale);

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < route.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(at(0), strokeWidth * 1.3, Paint()..color = Colors.green)
      ..drawCircle(
        at(route.length - 1),
        strokeWidth * 1.3,
        Paint()..color = color,
      );
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      old.route != route || old.color != color;
}
