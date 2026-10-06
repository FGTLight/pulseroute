import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/distance_unit.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../incidents/presentation/widgets/incident_tile.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/workout_detail_cubit.dart';
import '../widgets/route_map_preview.dart';
import '../widgets/workout_summary_view.dart';

/// Full workout: route map with nearby incidents, stats, splits and the
/// list of incidents that were near the route. Expects a
/// [WorkoutDetailCubit] (already loading).
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unit = context.select<SettingsCubit, DistanceUnit>(
      (c) => c.state.unit,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: BlocBuilder<WorkoutDetailCubit, WorkoutDetailState>(
        builder: (context, state) => switch (state) {
          WorkoutDetailState(status: WorkoutDetailStatus.loading) =>
            const LoadingView(),
          WorkoutDetailState(workout: final workout?) => WorkoutSummaryView(
            workout: workout,
            unit: unit,
            mapBuilder: (route) => RouteMapPreview(
              route: route,
              incidents: state.incidents ?? const [],
            ),
            footer: _IncidentsSection(state: state),
          ),
          _ => ErrorView(message: state.errorMessage ?? 'Workout not found.'),
        },
      ),
    );
  }
}

class _IncidentsSection extends StatelessWidget {
  const _IncidentsSection({required this.state});

  final WorkoutDetailState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final incidents = state.incidents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Incidents near your route', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (incidents == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.incidentsError != null)
          Text(
            "Couldn't load incidents: ${state.incidentsError}",
            style: textTheme.bodyMedium,
          )
        else if (incidents.isEmpty)
          Text(
            'No reported incidents within 50 m of your route.',
            style: textTheme.bodyMedium,
          )
        else
          for (final incident in incidents)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IncidentTile(incident: incident, onTap: () {}),
            ),
      ],
    );
  }
}
