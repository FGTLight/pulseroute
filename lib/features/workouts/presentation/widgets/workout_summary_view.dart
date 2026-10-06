import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/domain/distance_unit.dart';
import '../../../../core/domain/geo_point.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/activity_selector.dart';
import '../../domain/entities/workout.dart';
import 'route_map_preview.dart';

/// Builds the route map. Injectable so widget tests can skip the native map.
typedef RouteMapBuilder = Widget Function(List<GeoPoint> route);

Widget _defaultMap(List<GeoPoint> route) => RouteMapPreview(route: route);

/// Full summary of a finished workout: map, key numbers and splits.
class WorkoutSummaryView extends StatelessWidget {
  const WorkoutSummaryView({
    required this.workout,
    this.unit = DistanceUnit.km,
    this.mapBuilder = _defaultMap,
    this.footer,
    super.key,
  });

  final Workout workout;
  final DistanceUnit unit;
  final RouteMapBuilder mapBuilder;

  /// Extra content below the splits (e.g. nearby incidents).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRun = workout.activity == ActivityType.run;
    final date = DateFormat('EEE d MMM y · HH:mm').format(workout.startedAt);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                workout.activity.icon,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.activity.label,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(date, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (!workout.synced)
              Tooltip(
                message: 'Saved on this phone, will upload when online',
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (workout.route.length > 1) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(height: 220, child: mapBuilder(workout.route)),
          ),
          const SizedBox(height: 16),
        ],
        _MetricsCard(workout: workout, unit: unit, isRun: isRun),
        if (workout.splits.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SplitsCard(splits: workout.splits, unit: unit),
        ],
        ?footer,
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.workout,
    required this.unit,
    required this.isRun,
  });

  final Workout workout;
  final DistanceUnit unit;
  final bool isRun;

  @override
  Widget build(BuildContext context) {
    final metrics = <(String, String)>[
      ('Distance', Formatters.distance(workout.distanceM, unit)),
      ('Moving time', Formatters.duration(workout.duration)),
      if (isRun)
        ('Avg pace', Formatters.pace(workout.avgSpeedMps, unit))
      else
        ('Avg speed', Formatters.speed(workout.avgSpeedMps, unit)),
      ('Max speed', Formatters.speed(workout.maxSpeedMps, unit)),
      ('Elevation gain', Formatters.elevation(workout.elevationGainM, unit)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 16,
          children: [
            for (final (label, value) in metrics)
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One bar per split; the fastest one is highlighted.
class _SplitsCard extends StatelessWidget {
  const _SplitsCard({required this.splits, required this.unit});

  final List<Duration> splits;
  final DistanceUnit unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slowest = splits.reduce((a, b) => a > b ? a : b);
    final fastest = splits.reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Splits per ${unit.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < splits.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: Text('${i + 1}')),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          // Faster splits get longer bars.
                          value:
                              fastest.inMilliseconds / splits[i].inMilliseconds,
                          minHeight: 10,
                          color: splits[i] == fastest
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: .45),
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 52,
                      child: Text(
                        Formatters.duration(splits[i]),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontWeight: splits[i] == fastest
                              ? FontWeight.w700
                              : null,
                          color: splits[i] == slowest && splits.length > 1
                              ? scheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
