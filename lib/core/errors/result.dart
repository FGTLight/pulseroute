import 'failures.dart';

/// The outcome of an operation that can fail in an expected way.
///
/// Repositories return a [Result] instead of throwing, so callers are forced
/// by the type system to handle the [Failure] case.
sealed class Result<T> {
  const Result();

  /// Calls [onSuccess] or [onFailure] depending on the outcome.
  R fold<R>(R Function(T value) onSuccess, R Function(Failure f) onFailure) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Error(:final failure) => onFailure(failure),
      };

  bool get isSuccess => this is Success<T>;

  /// The value on success, otherwise `null`.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Error() => null,
  };

  /// The failure on error, otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Error(:final failure) => failure,
  };
}

/// A successful [Result] carrying [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// A failed [Result] carrying a [failure].
final class Error<T> extends Result<T> {
  const Error(this.failure);

  final Failure failure;
}
