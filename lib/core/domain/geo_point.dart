import 'package:equatable/equatable.dart';

/// A WGS84 coordinate, independent of any map SDK.
class GeoPoint extends Equatable {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}
