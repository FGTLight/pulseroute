import 'package:equatable/equatable.dart';

/// An expected error, translated from exceptions at the data layer so the
/// domain and presentation layers never deal with platform exceptions.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Human readable explanation, safe to show in the UI.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// No connection or the server could not be reached.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'You appear to be offline.']);
}

/// Wrong credentials, expired session, etc.
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// The server rejected or could not process the request.
final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Reading or writing the local database failed.
final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// The user denied a permission the feature needs.
final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {this.permanentlyDenied = false});

  /// If `true`, the app must send the user to the system settings.
  final bool permanentlyDenied;

  @override
  List<Object?> get props => [message, permanentlyDenied];
}

/// Location services (GPS) are turned off on the device.
final class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure([
    super.message = 'Turn on location services to track your workout.',
  ]);
}

/// The requested item does not exist (anymore).
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

/// Anything we did not anticipate.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
