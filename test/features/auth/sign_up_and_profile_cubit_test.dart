import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/domain/activity_type.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/core/utils/form_status.dart';
import 'package:pulseroute/features/auth/domain/entities/user_profile.dart';
import 'package:pulseroute/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulseroute/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulseroute/features/auth/presentation/cubit/profile_cubit.dart';
import 'package:pulseroute/features/auth/presentation/cubit/sign_up_cubit.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(ActivityType.run);
    registerFallbackValue(
      const UserProfile(
        id: '',
        displayName: '',
        preferredActivity: ActivityType.run,
      ),
    );
  });

  group('SignUpCubit', () {
    late MockAuthRepository repository;

    setUp(() => repository = MockAuthRepository());

    blocTest<SignUpCubit, SignUpState>(
      'signs up with the selected activity and reports email confirmation',
      setUp: () => when(
        () => repository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
          preferredActivity: any(named: 'preferredActivity'),
        ),
      ).thenAnswer((_) async => const Success(SignUpOutcome.confirmEmail)),
      build: () => SignUpCubit(signUp: SignUpWithEmail(repository)),
      act: (cubit) async {
        cubit.selectActivity(ActivityType.bike);
        await cubit.submit(
          displayName: ' Ana ',
          email: 'ana@example.com',
          password: 'secret123',
        );
      },
      expect: () => const [
        SignUpState(activity: ActivityType.bike),
        SignUpState(activity: ActivityType.bike, status: FormStatus.submitting),
        SignUpState(
          activity: ActivityType.bike,
          status: FormStatus.success,
          outcome: SignUpOutcome.confirmEmail,
        ),
      ],
      verify: (_) => verify(
        () => repository.signUp(
          email: 'ana@example.com',
          password: 'secret123',
          displayName: 'Ana',
          preferredActivity: ActivityType.bike,
        ),
      ).called(1),
    );
  });

  group('ProfileCubit', () {
    const profile = UserProfile(
      id: 'u1',
      displayName: 'Ana',
      preferredActivity: ActivityType.run,
    );
    late MockProfileRepository repository;

    setUp(() => repository = MockProfileRepository());

    ProfileCubit build() => ProfileCubit(
      getMyProfile: GetMyProfile(repository),
      updateProfile: UpdateProfile(repository),
    );

    blocTest<ProfileCubit, ProfileState>(
      'loads the profile',
      setUp: () =>
          when(() => repository.getMyProfile())
              .thenAnswer((_) async => const Success(profile)),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => const [
        ProfileState(),
        ProfileState(status: ProfileStatus.ready, profile: profile),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'keeps the old profile when saving fails',
      setUp: () =>
          when(() => repository.updateProfile(any()))
              .thenAnswer((_) async => const Err(NetworkFailure())),
      build: build,
      seed: () =>
          const ProfileState(status: ProfileStatus.ready, profile: profile),
      act: (cubit) => cubit.save(
        displayName: 'Ana B',
        preferredActivity: ActivityType.bike,
      ),
      expect: () => const [
        ProfileState(status: ProfileStatus.saving, profile: profile),
        ProfileState(
          status: ProfileStatus.ready,
          profile: profile,
          errorMessage: 'You appear to be offline.',
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'saves a trimmed display name',
      setUp: () => when(() => repository.updateProfile(any())).thenAnswer(
        (call) async => Success(call.positionalArguments.first as UserProfile),
      ),
      build: build,
      seed: () =>
          const ProfileState(status: ProfileStatus.ready, profile: profile),
      act: (cubit) => cubit.save(
        displayName: '  Ana B ',
        preferredActivity: ActivityType.bike,
      ),
      expect: () => [
        const ProfileState(status: ProfileStatus.saving, profile: profile),
        ProfileState(
          status: ProfileStatus.saved,
          profile: profile.copyWith(
            displayName: 'Ana B',
            preferredActivity: ActivityType.bike,
          ),
        ),
      ],
    );
  });
}
