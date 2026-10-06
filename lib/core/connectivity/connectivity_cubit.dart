import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the device has a network connection.
///
/// Takes a plain stream so it can be driven by `connectivity_plus` in the
/// app and by a controller in tests. `onReconnect` runs every time the
/// connection comes back (used to upload workouts recorded offline).
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit({
    required Stream<bool> onlineChanges,
    required Future<bool> Function() isOnline,
    Future<void> Function()? onReconnect,
  }) : _onReconnect = onReconnect,
       super(true) {
    unawaited(isOnline().then(_update, onError: (_) {}));
    _subscription = onlineChanges.listen(_update);
  }

  final Future<void> Function()? _onReconnect;
  late final StreamSubscription<bool> _subscription;

  void _update(bool online) {
    if (isClosed || online == state) return;
    emit(online);
    if (online) unawaited(_onReconnect?.call());
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
