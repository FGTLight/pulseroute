import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../auth/presentation/bloc/session_bloc.dart';
import '../../../settings/presentation/unit_context.dart';
import '../../domain/entities/incident.dart';
import '../bloc/incidents_bloc.dart';
import '../incident_style.dart';

/// Details of an incident with the community vote buttons. Reads the
/// incident from [IncidentsBloc] by id, so counters update live.
class IncidentDetailSheet extends StatelessWidget {
  const IncidentDetailSheet({required this.incidentId, super.key});

  final String incidentId;

  static Future<void> show(BuildContext context, String incidentId) {
    final bloc = context.read<IncidentsBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: IncidentDetailSheet(incidentId: incidentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncidentsBloc>().state;
    final incident = state.byId[incidentId];
    if (incident == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('This incident was resolved or removed.'),
      );
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final userId = context.select<SessionBloc, String?>(
      (bloc) => bloc.state.user?.id,
    );
    final mine = incident.isReportedBy(userId);
    final center = state.center;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: incident.category.color,
                  child: Icon(incident.category.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.category.label,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        [
                          'Reported ${Formatters.age(incident.createdAt, now)}',
                          if (center != null)
                            Formatters.shortDistance(
                              GeoMath.distance(center, incident.location),
                              context.distanceUnit,
                            ),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(incident.severity.label),
                  side: BorderSide(
                    color: incident.severity.color(theme.colorScheme),
                  ),
                ),
              ],
            ),
            if (incident.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(incident.description, style: theme.textTheme.bodyLarge),
            ],
            if (incident.photoUrl case final url?) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '${incident.confirmations} '
              '${incident.confirmations == 1 ? 'person' : 'people'} confirmed'
              ' · ${incident.resolutions} marked resolved',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _VoteButton(
                    label: 'Still there',
                    icon: Icons.thumb_up_alt_outlined,
                    selected: incident.myVote == IncidentVote.confirm,
                    // Reporters cannot confirm their own incident.
                    onPressed: mine
                        ? null
                        : () => _vote(context, incident, IncidentVote.confirm),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VoteButton(
                    label: 'Resolved',
                    icon: Icons.check_circle_outline_rounded,
                    selected: incident.myVote == IncidentVote.resolve,
                    onPressed: () =>
                        _vote(context, incident, IncidentVote.resolve),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _vote(BuildContext context, Incident incident, IncidentVote vote) {
    unawaited(HapticFeedback.selectionClick());
    context.read<IncidentsBloc>().add(IncidentVoteRequested(incident, vote));
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
    );
    return selected
        ? FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}
