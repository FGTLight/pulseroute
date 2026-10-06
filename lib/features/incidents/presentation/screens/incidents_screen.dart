import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/theme/map_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../map/presentation/widgets/incident_layer.dart';
import '../../../map/presentation/widgets/incident_layer_builder.dart';
import '../../../map/presentation/widgets/map_converters.dart';
import '../bloc/incidents_bloc.dart';
import '../report_flow.dart';
import '../widgets/incident_detail_sheet.dart';
import '../widgets/incident_tile.dart';

/// Nearby community incidents, on a map or as a list.
class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({this.startWithList = false, super.key});

  /// Open on the list instead of the map.
  final bool startWithList;

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  late bool _showList = widget.startWithList;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncidentsBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
        actions: [
          IconButton(
            tooltip: _showList ? 'Show map' : 'Show list',
            onPressed: () => setState(() => _showList = !_showList),
            icon: Icon(_showList ? Icons.map_outlined : Icons.list_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context.read<IncidentsBloc>().add(
              const IncidentsRefreshRequested(),
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: state.center == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'report',
              onPressed: () => openReportFlow(context, state.center!),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Report here'),
            ),
      body: switch (state.status) {
        IncidentsStatus.initial ||
        IncidentsStatus.loading when state.byId.isEmpty => const LoadingView(),
        IncidentsStatus.failure when state.byId.isEmpty => ErrorView(
          message: state.errorMessage ?? 'Could not load incidents.',
          onRetry: () => context.read<IncidentsBloc>().add(
            const IncidentsRefreshRequested(),
          ),
        ),
        _ => AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _showList
              ? _IncidentList(key: const ValueKey('list'), state: state)
              : _IncidentMap(key: const ValueKey('map'), center: state.center),
        ),
      },
    );
  }
}

class _IncidentMap extends StatelessWidget {
  const _IncidentMap({required this.center, super.key});

  final GeoPoint? center;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IncidentLayerBuilder(
          builder: (context, layer) => GoogleMap(
            initialCameraPosition: CameraPosition(
              target: center?.toLatLng() ?? defaultMapCenter,
              zoom: 14,
            ),
            style: MapStyles.forBrightness(Theme.of(context).brightness),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(bottom: 80),
            markers: layer.markers,
            circles: layer.circles,
            clusterManagers: IncidentLayer.clusterManagers,
            onLongPress: (p) => unawaited(
              openReportFlow(context, GeoPoint(p.latitude, p.longitude)),
            ),
          ),
        ),
        const Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Chip(
              avatar: Icon(Icons.touch_app_rounded, size: 18),
              label: Text('Long-press the map to report'),
            ),
          ),
        ),
      ],
    );
  }
}

class _IncidentList extends StatelessWidget {
  const _IncidentList({required this.state, super.key});

  final IncidentsState state;

  @override
  Widget build(BuildContext context) {
    final incidents = state.incidents;
    if (incidents.isEmpty) {
      return const EmptyState(
        icon: Icons.verified_user_rounded,
        title: 'All clear nearby',
        message: 'No active incidents within 3 km. Stay safe out there!',
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<IncidentsBloc>().add(const IncidentsRefreshRequested()),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: incidents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => IncidentTile(
          incident: incidents[i],
          from: state.center,
          onTap: () => IncidentDetailSheet.show(context, incidents[i].id),
        ),
      ),
    );
  }
}
