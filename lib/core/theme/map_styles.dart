import 'package:flutter/material.dart';

/// Google Maps JSON styles matching the app theme.
abstract final class MapStyles {
  /// Style for the given brightness (`null` keeps the default light map).
  static String? forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : null;

  /// Muted dark style so the route and markers stand out at night.
  static const dark = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2024"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8a8f98"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1d2024"}]},
  {"featureType": "poi", "elementType": "labels", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1f2b24"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2c3036"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3a3f47"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f1a24"}]}
]
''';
}
