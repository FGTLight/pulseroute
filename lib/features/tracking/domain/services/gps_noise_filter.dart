import '../../../../core/domain/activity_type.dart';
import '../../../../core/utils/geo_math.dart';
import '../entities/track_point.dart';

/// Why a fix was dropped (useful for debugging and tests).
enum RejectionReason { lowAccuracy, outOfOrder, impossibleJump, tooClose }

/// Result of [GpsNoiseFilter.process].
sealed class FilterResult {
  const FilterResult();
}

/// The fix was accepted and turned into [point] (smoothed).
final class Accepted extends FilterResult {
  const Accepted(this.point);

  final TrackPoint point;
}

/// The fix was dropped.
final class Rejected extends FilterResult {
  const Rejected(this.reason);

  final RejectionReason reason;
}

/// Cleans up raw GPS fixes before they become part of the route:
///
/// 1. **Low accuracy**: fixes with an accuracy radius above
///    [maxAccuracyM] are dropped (typical indoors or at start-up).
/// 2. **Impossible jumps**: a fix implying a speed above the activity's
///    [maxSpeedFor] since the last accepted point is dropped.
/// 3. **Jitter**: fixes closer than [minDistanceM] to the last point are
///    dropped, so standing still does not add distance.
/// 4. **Smoothing**: accepted positions are averaged with the previous
///    [smoothingWindow] raw fixes, weighted by 1 / accuracy². Averaging
///    makes the route trail the newest fix slightly, so [flush] appends the
///    last real fix when a segment ends (pause or finish).
///
/// The filter is stateful; call [reset] when a new segment starts.
class GpsNoiseFilter {
  GpsNoiseFilter({
    required this.activity,
    this.maxAccuracyM = 25,
    this.minDistanceM = 3,
    this.smoothingWindow = 3,
  });

  final ActivityType activity;
  final double maxAccuracyM;
  final double minDistanceM;
  final int smoothingWindow;

  final List<LocationFix> _window = [];
  TrackPoint? _last;
  LocationFix? _lastRaw;

  /// Upper bound for a believable speed, with a margin over world-class
  /// performances so real efforts are never filtered out.
  static double maxSpeedFor(ActivityType activity) => switch (activity) {
    ActivityType.run => 12, // ~43 km/h
    ActivityType.bike => 25, // 90 km/h
  };

  /// Starts a new segment: the next fix is compared with nothing.
  void reset() {
    _window.clear();
    _last = null;
    _lastRaw = null;
  }

  /// The last valid raw fix as a point, if the smoothed route has not
  /// reached it yet. Call before ending a segment so its final meters count.
  TrackPoint? flush({required int segment}) {
    final raw = _lastRaw;
    final last = _last;
    if (raw == null || last == null) return null;
    if (GeoMath.distance(last.point, raw.point) < minDistanceM) return null;
    final point = TrackPoint(
      lat: raw.lat,
      lng: raw.lng,
      timestamp: raw.timestamp,
      segment: segment,
      accuracyM: raw.accuracyM,
      altitudeM: raw.altitudeM,
      speedMps: raw.speedMps,
    );
    _last = point;
    return point;
  }

  FilterResult process(LocationFix fix, {required int segment}) {
    if (fix.accuracyM > maxAccuracyM) {
      return const Rejected(RejectionReason.lowAccuracy);
    }

    final last = _last;
    if (last != null) {
      final seconds =
          fix.timestamp.difference(last.timestamp).inMilliseconds / 1000;
      if (seconds <= 0) return const Rejected(RejectionReason.outOfOrder);

      final distance = GeoMath.distance(last.point, fix.point);
      // Allow the accuracy radius as slack so slow-but-noisy fixes pass.
      if ((distance - fix.accuracyM) / seconds > maxSpeedFor(activity)) {
        return const Rejected(RejectionReason.impossibleJump);
      }
    }

    _lastRaw = fix;
    _window.add(fix);
    if (_window.length > smoothingWindow) _window.removeAt(0);
    final smoothed = _smoothed(fix, segment);

    if (last != null &&
        GeoMath.distance(last.point, smoothed.point) < minDistanceM) {
      return const Rejected(RejectionReason.tooClose);
    }

    _last = smoothed;
    return Accepted(smoothed);
  }

  TrackPoint _smoothed(LocationFix fix, int segment) {
    var weightSum = 0.0;
    var lat = 0.0;
    var lng = 0.0;
    for (final f in _window) {
      final accuracy = f.accuracyM < 1 ? 1.0 : f.accuracyM;
      final weight = 1 / (accuracy * accuracy);
      weightSum += weight;
      lat += f.lat * weight;
      lng += f.lng * weight;
    }
    return TrackPoint(
      lat: lat / weightSum,
      lng: lng / weightSum,
      timestamp: fix.timestamp,
      segment: segment,
      accuracyM: fix.accuracyM,
      altitudeM: fix.altitudeM,
      speedMps: fix.speedMps,
    );
  }
}
