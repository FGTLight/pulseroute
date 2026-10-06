import '../../../../core/domain/activity_type.dart';
import '../../domain/entities/user_profile.dart';

/// Maps rows of the `profiles` table to and from [UserProfile].
abstract final class ProfileModel {
  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['display_name'] as String? ?? '',
    preferredActivity: ActivityType.fromName(
      json['preferred_activity'] as String?,
    ),
  );

  /// Columns the user is allowed to update.
  static Map<String, dynamic> toUpdateJson(UserProfile profile) => {
    'display_name': profile.displayName,
    'preferred_activity': profile.preferredActivity.name,
  };
}
