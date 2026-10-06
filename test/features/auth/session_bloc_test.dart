import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/features/auth/domain/entities/app_user.dart';
import 'package:pulseroute/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulseroute/features/auth/presentation/bloc/session_bloc.dart';

import '../../helpers/mocks.dart';

void main() {
  const user = AppUser(id: 'u1', email: 'ana@example.com');
  late MockAuthRepository repository;
  late StreamController<AppUser?> changes;

  setUp(() {
    repository = MockAuthRepository();
    changes = StreamController<AppUser?>.broadcast();
    when(() => repository.userChanges).thenAnswer((_) => changes.stream);
    when(() => repository.currentUser).thenReturn(null);
    when(() => repository.signOut())
        .thenAnswer((_) async => const Success(null));
  });

  tearDown(() => changes.close());

  SessionBloc build() =>
      SessionBloc(repository: repository, signOut: SignOut(repository));

  test('starts authenticated when a session was restored', () {
    when(() => repository.currentUser).thenReturn(user);
    expect(build().state, const SessionState.authenticated(user));
  });

  test('starts unauthenticated without a session', () {
    expect(build().state.isAuthenticated, isFalse);
  });

  blocTest<SessionBloc, SessionState>(
    'follows sign in and sign out from the auth provider',
    build: build,
    act: (_) async {
      changes.add(user);
      await pumpEventQueue();
      changes.add(null);
    },
    expect: () => const [
      SessionState.authenticated(user),
      SessionState.unauthenticated(),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'signs out even when the server call fails',
    setUp: () {
      when(() => repository.currentUser).thenReturn(user);
      when(() => repository.signOut())
          .thenAnswer((_) async => const Err(NetworkFailure()));
    },
    build: build,
    act: (bloc) => bloc.add(const SessionSignOutRequested()),
    expect: () => const [SessionState.unauthenticated()],
    verify: (_) => verify(() => repository.signOut()).called(1),
  );
}
