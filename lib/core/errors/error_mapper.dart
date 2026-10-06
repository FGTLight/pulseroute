import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'failures.dart';

/// Translates exceptions thrown by Supabase and the platform into
/// [Failure]s with messages that are safe to show to users.
Failure mapError(Object error) {
  return switch (error) {
    SocketException() || TimeoutException() => const NetworkFailure(),
    AuthRetryableFetchException() => const NetworkFailure(),
    AuthException(:final code, :final message) => AuthFailure(
      _authMessages[code] ?? message,
    ),
    PostgrestException(:final code) when code == 'PGRST116' =>
      const NotFoundFailure(),
    PostgrestException(:final code) when code == '42501' => const ServerFailure(
      'You are not allowed to do that.',
    ),
    PostgrestException(:final message) => ServerFailure(message),
    StorageException(:final message) => ServerFailure(message),
    _ => const UnexpectedFailure(),
  };
}

/// Friendlier wording for the most common Supabase Auth error codes.
const _authMessages = {
  'invalid_credentials': 'Wrong email or password.',
  'email_not_confirmed': 'Confirm your email address, then sign in.',
  'user_already_exists': 'An account with this email already exists.',
  'weak_password': 'Choose a stronger password.',
  'over_email_send_rate_limit':
      'Too many emails sent. Please wait a minute and try again.',
  'over_request_rate_limit': 'Too many attempts. Please try again later.',
  'otp_expired': 'This link has expired. Request a new one.',
};
