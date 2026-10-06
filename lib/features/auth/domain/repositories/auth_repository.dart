import '../../../../core/domain/activity_type.dart';
import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';

/// Outcome of a successful sign up.
enum SignUpOutcome {
  /// The account is ready and the user is signed in.
  signedIn,

  /// The project requires email confirmation before the first sign in.
  confirmEmail,
}

/// Authentication contract. Implementations translate provider errors into
/// `Failure`s, so callers never see provider-specific exceptions.
abstract interface class AuthRepository {
  /// The signed-in user, or `null`.
  AppUser? get currentUser;

  /// Emits whenever the user signs in or out.
  Stream<AppUser?> get userChanges;

  Future<Result<void>> signInWithPassword({
    required String email,
    required String password,
  });

  Future<Result<SignUpOutcome>> signUp({
    required String email,
    required String password,
    required String displayName,
    required ActivityType preferredActivity,
  });

  /// Emails a one-time sign-in link.
  Future<Result<void>> sendMagicLink({required String email});

  Future<Result<void>> signOut();

  /// Permanently deletes the account, its workouts, votes and photos.
  /// Reported incidents stay (community data) without the reporter.
  Future<Result<void>> deleteAccount();
}
