import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_model.dart';

/// [ProfileRepository] backed by the `profiles` table.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  @override
  Future<Result<UserProfile>> getMyProfile() async {
    final id = _userId;
    if (id == null) return const Err(AuthFailure('You are signed out.'));
    try {
      final row = await _client.from('profiles').select().eq('id', id).single();
      return Success(ProfileModel.fromJson(row));
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    try {
      final row = await _client
          .from('profiles')
          .update(ProfileModel.toUpdateJson(profile))
          .eq('id', profile.id)
          .select()
          .single();
      return Success(ProfileModel.fromJson(row));
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }
}
