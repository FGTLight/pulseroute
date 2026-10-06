import '../../../../core/errors/result.dart';
import '../entities/user_profile.dart';

/// Reads and updates the signed-in user's profile.
abstract interface class ProfileRepository {
  Future<Result<UserProfile>> getMyProfile();

  Future<Result<UserProfile>> updateProfile(UserProfile profile);
}
