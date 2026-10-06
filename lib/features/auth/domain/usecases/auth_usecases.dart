import '../../../../core/domain/activity_type.dart';
import '../../../../core/errors/result.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';

// Use cases are the application's entry points into the domain. They are
// intentionally small: each normalizes its input and delegates to a
// repository, which keeps blocs free of business rules.

/// Signs in with email and password.
class SignInWithPassword {
  const SignInWithPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String email,
    required String password,
  }) => _repository.signInWithPassword(
    email: email.trim().toLowerCase(),
    password: password,
  );
}

/// Creates an account. The profile is created by a database trigger from
/// the metadata sent here.
class SignUpWithEmail {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<SignUpOutcome>> call({
    required String email,
    required String password,
    required String displayName,
    required ActivityType preferredActivity,
  }) => _repository.signUp(
    email: email.trim().toLowerCase(),
    password: password,
    displayName: displayName.trim(),
    preferredActivity: preferredActivity,
  );
}

/// Emails a passwordless sign-in link.
class SendMagicLink {
  const SendMagicLink(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) =>
      _repository.sendMagicLink(email: email.trim().toLowerCase());
}

/// Signs the user out.
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}

/// Deletes the account on the server, then everything stored on the device.
class DeleteAccount {
  const DeleteAccount(this._repository, this._clearLocalData);

  final AuthRepository _repository;
  final Future<void> Function() _clearLocalData;

  Future<Result<void>> call() async {
    final result = await _repository.deleteAccount();
    if (result.isSuccess) await _clearLocalData();
    return result;
  }
}

/// Loads the signed-in user's profile.
class GetMyProfile {
  const GetMyProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<UserProfile>> call() => _repository.getMyProfile();
}

/// Saves profile changes.
class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<UserProfile>> call(UserProfile profile) => _repository
      .updateProfile(profile.copyWith(displayName: profile.displayName.trim()));
}
