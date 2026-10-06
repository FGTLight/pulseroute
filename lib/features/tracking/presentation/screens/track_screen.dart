import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/distance_unit.dart';
import '../../../../core/router/app_routes.dart';
import '../bloc/tracking_bloc.dart';
import '../widgets/location_rationale_sheet.dart';
import '../widgets/tracking_map.dart';
import '../widgets/tracking_panel.dart';

/// Live workout: full-screen map with the route and a stats panel.
///
/// Expects the app-wide [TrackingBloc] above it, so recording continues
/// while the user browses other tabs.
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  /// Height reserved for the panel when padding the map.
  static const _panelHeight = 230.0;

  Future<void> _onStateChanged(
    BuildContext context,
    TrackingState state,
  ) async {
    final bloc = context.read<TrackingBloc>();
    final messenger = ScaffoldMessenger.of(context);

    if (state.errorMessage case final message?) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
    if (state.showRationale) {
      final accepted = await LocationRationaleSheet.show(context);
      bloc.add(
        accepted
            ? const TrackingRationaleAccepted()
            : const TrackingRationaleDismissed(),
      );
    }
    if (state.status == TrackingStatus.finished && context.mounted) {
      await context.push(
        AppRoutes.workoutSummary,
        extra: state.finishedWorkout,
      );
      bloc.add(const TrackingSummaryDismissed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<TrackingBloc, TrackingState>(
        listenWhen: (a, b) =>
            (b.errorMessage != null && a.errorMessage != b.errorMessage) ||
            (b.showRationale && !a.showRationale) ||
            (b.status == TrackingStatus.finished &&
                a.status != TrackingStatus.finished),
        listener: (context, state) =>
            unawaited(_onStateChanged(context, state)),
        child: Stack(
          children: [
            Positioned.fill(
              child: BlocBuilder<TrackingBloc, TrackingState>(
                buildWhen: (a, b) =>
                    a.workout?.points.length != b.workout?.points.length ||
                    a.position != b.position ||
                    a.accessIssue != b.accessIssue,
                builder: (context, state) => TrackingMap(
                  segments: state.routeSegments,
                  position: state.position,
                  showMyLocation: state.accessIssue == null,
                  bottomPadding: _panelHeight,
                ),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _StatusChip()),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: TrackingPanel(unit: DistanceUnit.km),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recording / paused / weak GPS indicator at the top of the map.
class _StatusChip extends StatelessWidget {
  const _StatusChip();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TrackingBloc>().state;
    final scheme = Theme.of(context).colorScheme;

    final (label, color, icon) = switch (state) {
      TrackingState(status: TrackingStatus.recording, gpsWeak: true) => (
        'Weak GPS signal',
        scheme.tertiary,
        Icons.gps_not_fixed_rounded,
      ),
      TrackingState(status: TrackingStatus.recording) => (
        'Recording',
        scheme.error,
        Icons.fiber_manual_record_rounded,
      ),
      TrackingState(status: TrackingStatus.paused) => (
        'Paused',
        scheme.secondary,
        Icons.pause_rounded,
      ),
      _ => (null, null, null),
    };
    if (label == null) return const SizedBox.shrink();

    return Align(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Chip(
          avatar: Icon(icon, color: color, size: 18),
          label: Text(label),
          backgroundColor: scheme.surface,
          elevation: 2,
        ),
      ),
    );
  }
}
