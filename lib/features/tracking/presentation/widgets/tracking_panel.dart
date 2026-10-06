import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/distance_unit.dart';
import '../../../../core/widgets/activity_selector.dart';
import '../bloc/tracking_bloc.dart';
import 'stats_grid.dart';
import 'tracking_notices.dart';

/// Bottom panel of the tracking screen: notices, live stats and controls.
class TrackingPanel extends StatelessWidget {
  const TrackingPanel({required this.unit, super.key});

  final DistanceUnit unit;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TrackingBloc>().state;
    final bloc = context.read<TrackingBloc>();
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.accessIssue case final issue?) ...[
                  AccessIssueCard(
                    issue: issue,
                    onFix: () => bloc.add(const TrackingSettingsRequested()),
                  ),
                  const SizedBox(height: 12),
                ],
                if (state.showBatteryTip && !state.isActive) ...[
                  BatteryTipCard(
                    onAllow: () =>
                        bloc.add(const TrackingBatteryExemptionRequested()),
                    onDismiss: () =>
                        bloc.add(const TrackingBatteryTipDismissed()),
                  ),
                  const SizedBox(height: 12),
                ],
                if (state.isActive ||
                    state.status == TrackingStatus.saving) ...[
                  StatsGrid(
                    stats: state.stats,
                    activity: state.activity,
                    unit: unit,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  ActivitySelector(
                    value: state.activity,
                    onChanged: state.status == TrackingStatus.idle
                        ? (a) => bloc.add(TrackingActivitySelected(a))
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                _Controls(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final TrackingState state;

  Future<void> _confirmDiscard(BuildContext context) async {
    final bloc = context.read<TrackingBloc>();
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('Your route and stats will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard ?? false) bloc.add(const TrackingDiscardRequested());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TrackingBloc>();

    void haptic(TrackingEvent event) {
      unawaited(HapticFeedback.mediumImpact());
      bloc.add(event);
    }

    return switch (state.status) {
      TrackingStatus.idle || TrackingStatus.finished => FilledButton.icon(
        key: const Key('startButton'),
        onPressed: () => haptic(const TrackingStartRequested()),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start'),
      ),
      TrackingStatus.starting || TrackingStatus.saving => const FilledButton(
        onPressed: null,
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      TrackingStatus.recording => FilledButton.tonalIcon(
        key: const Key('pauseButton'),
        onPressed: () => haptic(const TrackingPauseRequested()),
        icon: const Icon(Icons.pause_rounded),
        label: const Text('Pause'),
      ),
      TrackingStatus.paused => Row(
        children: [
          IconButton.outlined(
            tooltip: 'Discard',
            onPressed: () => _confirmDiscard(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('finishButton'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => haptic(const TrackingStopRequested()),
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Finish'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              key: const Key('resumeButton'),
              onPressed: () => haptic(const TrackingResumeRequested()),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume'),
            ),
          ),
        ],
      ),
    };
  }
}
