/// Returns the current time. Injected so time-dependent logic is testable.
typedef Clock = DateTime Function();

/// Emits periodic ticks (e.g. to refresh the workout timer every second).
/// Injected so tests can drive time manually.
abstract interface class Ticker {
  Stream<void> tick(Duration interval);
}

/// [Ticker] backed by [Stream.periodic].
class PeriodicTicker implements Ticker {
  const PeriodicTicker();

  @override
  Stream<void> tick(Duration interval) => Stream<void>.periodic(interval);
}
