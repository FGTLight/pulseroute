import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/core/utils/form_status.dart';
import 'package:pulseroute/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulseroute/features/auth/presentation/cubit/sign_in_cubit.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  SignInCubit build() => SignInCubit(
    signInWithPassword: SignInWithPassword(repository),
    sendMagicLink: SendMagicLink(repository),
  );

  blocTest<SignInCubit, SignInState>(
    'signs in with a normalized email',
    setUp: () => when(
      () => repository.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Success(null)),
    build: build,
    act: (cubit) =>
        cubit.submit(email: '  Ana@Example.com ', password: 'secret123'),
    expect: () => const [
      SignInState(status: FormStatus.submitting),
      SignInState(status: FormStatus.success),
    ],
    verify: (_) => verify(
      () => repository.signInWithPassword(
        email: 'ana@example.com',
        password: 'secret123',
      ),
    ).called(1),
  );

  blocTest<SignInCubit, SignInState>(
    'exposes the failure message',
    setUp: () =>
        when(
          () => repository.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const Err(AuthFailure('Wrong email or password.')),
        ),
    build: build,
    act: (cubit) =>
        cubit.submit(email: 'ana@example.com', password: 'nope1234'),
    expect: () => const [
      SignInState(status: FormStatus.submitting),
      SignInState(
        status: FormStatus.failure,
        errorMessage: 'Wrong email or password.',
      ),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'sends a magic link in magic link mode',
    setUp: () =>
        when(() => repository.sendMagicLink(email: any(named: 'email')))
            .thenAnswer((_) async => const Success(null)),
    build: build,
    act: (cubit) async {
      cubit.selectMethod(SignInMethod.magicLink);
      await cubit.submit(email: 'ana@example.com');
    },
    expect: () => const [
      SignInState(method: SignInMethod.magicLink),
      SignInState(
        method: SignInMethod.magicLink,
        status: FormStatus.submitting,
      ),
      SignInState(
        method: SignInMethod.magicLink,
        status: FormStatus.success,
        magicLinkSentTo: 'ana@example.com',
      ),
    ],
    verify: (_) => verifyNever(
      () => repository.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ),
  );
}
