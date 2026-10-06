import 'package:flutter/material.dart';

import '../../domain/repositories/location_repository.dart';

/// Explains why location is unavailable and how to fix it.
class AccessIssueCard extends StatelessWidget {
  const AccessIssueCard({required this.issue, required this.onFix, super.key});

  final LocationAccess issue;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final (title, message, action) = switch (issue) {
      LocationAccess.serviceDisabled => (
        'Location is turned off',
        'Turn on location services to record your route.',
        'Turn on',
      ),
      LocationAccess.deniedForever => (
        'Location permission blocked',
        'Allow location for PulseRoute in the system settings.',
        'Open settings',
      ),
      _ => (
        'Location permission needed',
        'PulseRoute needs your location to map your workout.',
        'Open settings',
      ),
    };
    return _Notice(
      icon: Icons.location_off_rounded,
      title: title,
      message: message,
      action: action,
      onAction: onFix,
      error: true,
    );
  }
}

/// Suggests disabling battery optimization for reliable background tracking.
class BatteryTipCard extends StatelessWidget {
  const BatteryTipCard({
    required this.onAllow,
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onAllow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return _Notice(
      icon: Icons.battery_alert_rounded,
      title: 'Keep tracking with the screen off',
      message:
          'Some phones stop apps in the background to save battery. Allow '
          'PulseRoute to run without restrictions during workouts.',
      action: 'Allow',
      onAction: onAllow,
      onDismiss: onDismiss,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
    this.onDismiss,
    this.error = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;
  final VoidCallback? onDismiss;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final background = error
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = error
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 4, right: 8),
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDismiss != null)
                  TextButton(onPressed: onDismiss, child: const Text('Later')),
                TextButton(onPressed: onAction, child: Text(action)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
