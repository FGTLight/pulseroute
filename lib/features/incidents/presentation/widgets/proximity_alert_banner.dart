import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/proximity_alert_cubit.dart';
import '../incident_style.dart';
import 'incident_detail_sheet.dart';

/// In-app version of the proximity alert, shown on top of the tracking map.
/// Hides itself after [visibleFor]; the system notification stays.
class ProximityAlertBanner extends StatefulWidget {
  const ProximityAlertBanner({super.key});

  static const visibleFor = Duration(seconds: 12);

  @override
  State<ProximityAlertBanner> createState() => _ProximityAlertBannerState();
}

class _ProximityAlertBannerState extends State<ProximityAlertBanner> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProximityAlertCubit, ProximityAlertState>(
      listenWhen: (a, b) => b.latest != null && a.latest != b.latest,
      listener: (context, state) {
        _timer?.cancel();
        _timer = Timer(
          ProximityAlertBanner.visibleFor,
          context.read<ProximityAlertCubit>().dismiss,
        );
      },
      builder: (context, state) {
        final alert = state.latest;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
          child: alert == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(alert.incident.id),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Material(
                    color: alert.incident.category.color,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      onTap: () =>
                          IncidentDetailSheet.show(context, alert.incident.id),
                      textColor: Colors.white,
                      iconColor: Colors.white,
                      leading: Icon(alert.incident.category.icon, size: 32),
                      title: Text(
                        '${alert.incident.category.label} ahead',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if (alert.distanceM == 0)
                            "You're inside the area"
                          else
                            'in ${alert.distanceM.round()} m',
                          if (alert.incident.description.isNotEmpty)
                            alert.incident.description,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Dismiss',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: context.read<ProximityAlertCubit>().dismiss,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
