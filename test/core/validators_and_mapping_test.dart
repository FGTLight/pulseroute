import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/core/errors/error_mapper.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/router/app_router.dart';
import 'package:pulseroute/core/router/app_routes.dart';
import 'package:pulseroute/core/utils/validators.dart';
import 'package:pulseroute/features/auth/data/models/profile_model.dart';
import 'package:pulseroute/features/auth/domain/entities/app_user.dart';
import 'package:pulseroute/features/auth/presentation/bloc/session_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('ana@'), isNotNull);
      expect(Validators.email(' ana@example.com '), isNull);
    });

    test('password needs 8 characters', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });

    test('display name', () {
      expect(Validators.displayName('   '), isNotNull);
      expect(Validators.displayName('a' * 51), isNotNull);
      expect(Validators.displayName('Ana'), isNull);
    });
  });

  group('mapError', () {
    test('network errors', () {
      expect(mapError(const SocketException('down')), isA<NetworkFailure>());
      expect(
        mapError(AuthRetryableFetchException(message: 'x')),
        isA<NetworkFailure>(),
      );
    });

    test('known auth codes get friendly messages', () {
      final failure = mapError(
        const AuthApiException('Invalid login', code: 'invalid_credentials'),
      );
      expect(failure, const AuthFailure('Wrong email or password.'));
    });

    test('row not found and permission errors', () {
      expect(
        mapError(const PostgrestException(message: 'x', code: 'PGRST116')),
        isA<NotFoundFailure>(),
      );
      expect(
        mapError(const PostgrestException(message: 'x', code: '42501')),
        const ServerFailure('You are not allowed to do that.'),
      );
    });

    test('anything else is unexpected', () {
      expect(mapError(StateError('boom')), isA<UnexpectedFailure>());
    });
  });

  group('ProfileModel', () {
    test('parses a row and falls back to run', () {
      final profile = ProfileModel.fromJson({
        'id': 'u1',
        'display_name': 'Ana',
        'preferred_activity': 'skate',
      });
      expect(profile.preferredActivity, ActivityType.run);
      expect(ProfileModel.toUpdateJson(profile), {
        'display_name': 'Ana',
        'preferred_activity': 'run',
      });
    });
  });

  group('authRedirect', () {
    const signedIn = SessionState.authenticated(
      AppUser(id: 'u1', email: 'ana@example.com'),
    );
    const signedOut = SessionState.unauthenticated();

    test('signed-out users go to sign in', () {
      expect(authRedirect(signedOut, AppRoutes.track), AppRoutes.signIn);
      expect(authRedirect(signedOut, AppRoutes.signUp), isNull);
    });

    test('signed-in users leave the auth screens', () {
      expect(authRedirect(signedIn, AppRoutes.signIn), AppRoutes.track);
      expect(authRedirect(signedIn, AppRoutes.history), isNull);
    });
  });
}
