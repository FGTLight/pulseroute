import 'package:flutter/material.dart';

/// Explains, before the system dialog, why PulseRoute needs location.
///
/// Google Play requires a prominent disclosure for location access; this is
/// it. Returns `true` if the user wants to continue.
class LocationRationaleSheet extends StatelessWidget {
  const LocationRationaleSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const LocationRationaleSheet(),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your location, your workout', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            const _Reason(
              icon: Icons.route_rounded,
              text:
                  'Record your route, distance and pace while you run or '
                  'ride.',
            ),
            const _Reason(
              icon: Icons.screen_lock_portrait_rounded,
              text:
                  'Keep recording with the screen off. A notification is '
                  'shown the whole time, and tracking stops when you finish.',
            ),
            const _Reason(
              icon: Icons.warning_amber_rounded,
              text:
                  'Warn you about incidents reported by other users near '
                  'your path.',
            ),
            const _Reason(
              icon: Icons.lock_outline_rounded,
              text:
                  'Your location is only used during workouts and your '
                  'routes are private to your account.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
