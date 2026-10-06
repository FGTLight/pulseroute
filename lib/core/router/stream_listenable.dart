import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts streams into a [Listenable], so `GoRouter.refreshListenable`
/// re-runs its redirects whenever any of them emits (e.g. auth changes).
class StreamListenable extends ChangeNotifier {
  StreamListenable(List<Stream<Object?>> streams) {
    _subscriptions = [
      for (final s in streams) s.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
