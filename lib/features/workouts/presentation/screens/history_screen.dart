import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/domain/distance_unit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/activity_selector.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/workout_preview.dart';
import '../cubit/history_cubit.dart';
import '../widgets/route_thumbnail.dart';

/// Finished workouts with weekly totals. Expects a [HistoryCubit].
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unit = context.select<SettingsCubit, DistanceUnit>(
      (c) => c.state.unit,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          BlocSelector<HistoryCubit, HistoryState, bool>(
            selector: (s) => s.refreshing,
            builder: (context, refreshing) => IconButton(
              tooltip: 'Sync',
              onPressed: refreshing
                  ? null
                  : () => unawaited(context.read<HistoryCubit>().refresh()),
              icon: refreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
            ),
          ),
        ],
      ),
      body: BlocConsumer<HistoryCubit, HistoryState>(
        listenWhen: (a, b) => b.errorMessage != null,
        listener: (context, state) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!))),
        builder: (context, state) {
          if (state.status == HistoryStatus.loading) return const LoadingView();
          return RefreshIndicator(
            onRefresh: context.read<HistoryCubit>().refresh,
            child: state.workouts.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No workouts yet',
                        message:
                            'Your finished runs and rides will show up here.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: state.workouts.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => i == 0
                        ? _WeekCard(totals: state.thisWeek, unit: unit)
                        : _WorkoutCard(
                            workout: state.workouts[i - 1],
                            unit: unit,
                          ),
                  ),
          );
        },
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.totals, required this.unit});

  final HistoryTotals totals;
  final DistanceUnit unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final items = [
      ('Workouts', '${totals.workouts}'),
      ('Distance', Formatters.distance(totals.distanceM, unit)),
      ('Time', Formatters.duration(totals.duration)),
    ];

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week',
              style: textTheme.titleSmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (label, value) in items)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          label,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout, required this.unit});

  final WorkoutPreview workout;
  final DistanceUnit unit;

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('It will be removed from all your devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRun = workout.activity == ActivityType.run;
    final rate = isRun
        ? Formatters.pace(workout.avgSpeedMps, unit)
        : Formatters.speed(workout.avgSpeedMps, unit);

    return Dismissible(
      key: ValueKey(workout.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          unawaited(context.read<HistoryCubit>().delete(workout.id)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.workoutDetail(workout.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                RouteThumbnail(route: workout.preview),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(workout.activity.icon, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              DateFormat('EEE d MMM · HH:mm')
                                  .format(workout.startedAt),
                              style: textTheme.labelLarge,
                            ),
                          ),
                          if (!workout.synced)
                            const Tooltip(
                              message: 'Not uploaded yet',
                              child: Icon(Icons.cloud_off_rounded, size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.distance(workout.distanceM, unit),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${Formatters.duration(workout.duration)} · $rate',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
