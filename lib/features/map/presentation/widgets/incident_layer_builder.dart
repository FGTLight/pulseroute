import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/bloc/incidents_bloc.dart';
import '../../../incidents/presentation/widgets/incident_detail_sheet.dart';
import 'incident_layer.dart';
import 'incident_marker_icons.dart';

/// Builds an [IncidentLayer] from the app-wide [IncidentsBloc] and the
/// custom marker icons; tapping an incident opens its details.
class IncidentLayerBuilder extends StatefulWidget {
  const IncidentLayerBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, IncidentLayer layer) builder;

  @override
  State<IncidentLayerBuilder> createState() => _IncidentLayerBuilderState();
}

class _IncidentLayerBuilderState extends State<IncidentLayerBuilder> {
  IncidentMarkerIcons? _icons;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_icons != null) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    unawaited(
      IncidentMarkerIcons.cached(dpr).then((icons) {
        if (mounted) setState(() => _icons = icons);
      }, onError: (_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The map is only replaced when an incident changes (immutable map).
    final byId = context.select<IncidentsBloc, Map<String, Incident>>(
      (bloc) => bloc.state.byId,
    );
    return widget.builder(
      context,
      IncidentLayer(
        incidents: byId.values.toList(),
        icons: _icons,
        onTap: (i) => IncidentDetailSheet.show(context, i.id),
      ),
    );
  }
}
