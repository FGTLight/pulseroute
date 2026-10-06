import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/incident_style.dart';

/// Draws category-colored marker icons at runtime (no image assets needed)
/// and caches one per category.
class IncidentMarkerIcons {
  IncidentMarkerIcons._(this._icons);

  final Map<IncidentCategory, BitmapDescriptor> _icons;

  /// Logical size of a marker on the map.
  static const size = 40.0;

  BitmapDescriptor operator [](IncidentCategory category) =>
      _icons[category] ?? BitmapDescriptor.defaultMarker;

  static final _cache = <double, Future<IncidentMarkerIcons>>{};

  /// Icons for [devicePixelRatio], rendered once and reused by every map.
  static Future<IncidentMarkerIcons> cached(double devicePixelRatio) =>
      _cache[devicePixelRatio] ??= create(devicePixelRatio);

  /// Renders every icon at the screen's pixel ratio.
  static Future<IncidentMarkerIcons> create(double devicePixelRatio) async {
    final icons = <IncidentCategory, BitmapDescriptor>{};
    for (final category in IncidentCategory.values) {
      final bytes = await _paint(category, devicePixelRatio);
      icons[category] = BitmapDescriptor.bytes(
        bytes,
        width: size,
        height: size,
      );
    }
    return IncidentMarkerIcons._(icons);
  }

  static Future<Uint8List> _paint(IncidentCategory category, double dpr) async {
    final px = size * dpr;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(px / 2, px / 2);
    final radius = px / 2 - 2 * dpr;

    canvas
      // Soft shadow so markers read well on any map style.
      ..drawCircle(
        center.translate(0, dpr),
        radius,
        Paint()
          ..color = Colors.black38
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * dpr),
      )
      ..drawCircle(center, radius, Paint()..color = Colors.white)
      ..drawCircle(center, radius - 2.5 * dpr, Paint()..color = category.color);

    final icon = category.icon;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: radius * 1.1,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );

    final image = await recorder.endRecording().toImage(px.ceil(), px.ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
