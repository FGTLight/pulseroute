import 'package:equatable/equatable.dart';

import '../../../../core/domain/activity_type.dart';

/// Public profile of a user.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.preferredActivity,
  });

  final String id;
  final String displayName;
  final ActivityType preferredActivity;

  UserProfile copyWith({String? displayName, ActivityType? preferredActivity}) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      preferredActivity: preferredActivity ?? this.preferredActivity,
    );
  }

  @override
  List<Object?> get props => [id, displayName, preferredActivity];
}
