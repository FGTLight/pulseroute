import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/geo_point.dart';
import '../../../core/router/app_routes.dart';
import '../domain/entities/incident.dart';
import 'bloc/incidents_bloc.dart';

/// Opens the report form at [location] and adds the new incident to the map
/// as soon as it is saved (Realtime then confirms it for everyone else).
Future<void> openReportFlow(BuildContext context, GeoPoint location) async {
  final bloc = context.read<IncidentsBloc>();
  final messenger = ScaffoldMessenger.of(context);
  final created = await context.push<Incident>(
    AppRoutes.reportIncident,
    extra: location,
  );
  if (created == null) return;
  bloc.add(IncidentAdded(created));
  messenger.showSnackBar(
    const SnackBar(content: Text('Thanks! Your report is now on the map.')),
  );
}
