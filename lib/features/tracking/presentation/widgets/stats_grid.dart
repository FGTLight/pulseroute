import 'package:flutter/material.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/domain/distance_unit.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/workout_stats.dart';

/// Live numbers: big duration and distance, then pace/speed and elevation.
///
/// Runners think in pace (min/km), cyclists in speed (km/h).
class StatsGrid extends StatelessWidget {
  const StatsGrid({
    required this.stats,
    required this.activity,
    required this.unit,
    super.key,
  });

  final WorkoutStats stats;
  final ActivityType activity;
  final DistanceUnit unit;

  @override
  Widget build(BuildContext context) {
    final isRun = activity == ActivityType.run;
    String rate(double mps) =>
        isRun ? Formatters.pace(mps, unit) : Formatters.speed(mps, unit);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Duration',
                value: Formatters.duration(stats.duration),
                large: true,
              ),
            ),
            Expanded(
              child: StatTile(
                label: 'Distance',
                value: Formatters.distance(stats.distanceM, unit),
                large: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: isRun ? 'Pace' : 'Speed',
                value: rate(stats.currentSpeedMps),
              ),
            ),
            Expanded(
              child: StatTile(
                label: isRun ? 'Avg pace' : 'Avg speed',
                value: rate(stats.avgSpeedMps),
              ),
            ),
            Expanded(
              child: StatTile(
                label: 'Elevation',
                value: '+${Formatters.elevation(stats.elevationGainM, unit)}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A labelled number.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.large = false,
    super.key,
  });

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style:
                  (large
                          ? theme.textTheme.headlineMedium
                          : theme.textTheme.titleMedium)
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
