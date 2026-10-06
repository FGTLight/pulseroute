import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../connectivity/connectivity_cubit.dart';

/// Shows [OfflineBanner] above [child] while offline. The banner already
/// covers the status bar, so the child's top padding is removed meanwhile.
class OfflineAware extends StatelessWidget {
  const OfflineAware({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityCubit>().state;
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(
          child: online
              ? child
              : MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                ),
        ),
      ],
    );
  }
}

/// Thin strip shown at the top of the app while offline. Tracking keeps
/// working; only the community features need the network.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityCubit>().state;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: online
          ? const SizedBox(width: double.infinity)
          : Material(
              color: scheme.inverseSurface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 18,
                        color: scheme.onInverseSurface,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "You're offline. Workouts are saved and will upload "
                          'later.',
                          style: TextStyle(color: scheme.onInverseSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
