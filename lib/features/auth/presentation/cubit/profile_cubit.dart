import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/activity_type.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Lifecycle of the profile screen.
enum ProfileStatus { loading, ready, saving, saved, failure }

/// State of the profile screen.
final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.profile,
    this.errorMessage,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

/// Loads and edits the signed-in user's profile.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetMyProfile getMyProfile,
    required UpdateProfile updateProfile,
  }) : _getMyProfile = getMyProfile,
       _updateProfile = updateProfile,
       super(const ProfileState());

  final GetMyProfile _getMyProfile;
  final UpdateProfile _updateProfile;

  Future<void> load() async {
    emit(const ProfileState());
    final result = await _getMyProfile();
    emit(
      result.fold(
        (profile) =>
            ProfileState(status: ProfileStatus.ready, profile: profile),
        (f) => ProfileState(
          status: ProfileStatus.failure,
          errorMessage: f.message,
        ),
      ),
    );
  }

  Future<void> save({
    required String displayName,
    required ActivityType preferredActivity,
  }) async {
    final current = state.profile;
    if (current == null || state.status == ProfileStatus.saving) return;
    emit(ProfileState(status: ProfileStatus.saving, profile: current));

    final result = await _updateProfile(
      current.copyWith(
        displayName: displayName,
        preferredActivity: preferredActivity,
      ),
    );
    emit(
      result.fold(
        (profile) =>
            ProfileState(status: ProfileStatus.saved, profile: profile),
        (f) => ProfileState(
          status: ProfileStatus.ready,
          profile: current,
          errorMessage: f.message,
        ),
      ),
    );
  }
}
