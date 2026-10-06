import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulseroute/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:pulseroute/features/auth/presentation/screens/sign_in_screen.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => SignInCubit(
            signInWithPassword: SignInWithPassword(repository),
            sendMagicLink: SendMagicLink(repository),
          ),
          child: const SignInScreen(),
        ),
      ),
    );
  }

  testWidgets('validates the fields before calling the backend', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byKey(const Key('emailField')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('passwordField')), '123');
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    verifyNever(
      () => repository.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows the error message from a failed sign in', (tester) async {
    when(
      () => repository.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Err(AuthFailure('Wrong email or password.')),
    );
    await pump(tester);

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'ana@example.com',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'secret123');
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pumpAndSettle();

    expect(find.text('Wrong email or password.'), findsOneWidget);
  });

  testWidgets('magic link mode hides the password and confirms sending', (
    tester,
  ) async {
    when(() => repository.sendMagicLink(email: any(named: 'email')))
        .thenAnswer((_) async => const Success(null));
    await pump(tester);

    await tester.tap(find.text('Magic link'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('passwordField')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'ana@example.com',
    );
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pumpAndSettle();

    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.textContaining('ana@example.com'), findsOneWidget);
  });
}
