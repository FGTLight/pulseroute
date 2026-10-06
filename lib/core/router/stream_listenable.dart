import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] into a [Listenable], so `GoRouter.refreshListenable`
/// re-runs its redirects every time the stream emits (e.g. auth changes).
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
