import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// [AuthRepository] backed by Supabase Auth.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// Deep link that opens the app from a magic link email. It must be listed
  /// in Supabase → Authentication → URL Configuration → Redirect URLs.
  static const redirectUrl = 'io.pulseroute://login-callback';

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges => _auth.onAuthStateChange
      .map((state) => _toAppUser(state.session?.user))
      .distinct();

  @override
  Future<Result<void>> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _guard(() => _auth.signInWithPassword(email: email, password: password));

  @override
  Future<Result<SignUpOutcome>> signUp({
    required String email,
    required String password,
    required String displayName,
    required ActivityType preferredActivity,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectUrl,
        // Read by the `handle_new_user` trigger to create the profile.
        data: {
          'display_name': displayName,
          'preferred_activity': preferredActivity.name,
        },
      );
      // Without a session the project requires confirming the email first.
      return Success(
        response.session == null
            ? SignUpOutcome.confirmEmail
            : SignUpOutcome.signedIn,
      );
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }

  @override
  Future<Result<void>> sendMagicLink({required String email}) => _guard(
    () => _auth.signInWithOtp(email: email, emailRedirectTo: redirectUrl),
  );

  @override
  Future<Result<void>> signOut() => _guard(_auth.signOut);

  @override
  Future<Result<void>> deleteAccount() => _guard(() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    // Supabase blocks deleting Storage objects from SQL, so photos are
    // removed through the API before the account row disappears.
    final bucket = _client.storage.from('incident-photos');
    final photos = await bucket.list(path: userId);
    if (photos.isNotEmpty) {
      await bucket.remove([for (final f in photos) '$userId/${f.name}']);
    }
    await _client.rpc<void>('delete_account');
    await _auth.signOut();
  });

  static AppUser? _toAppUser(User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email ?? '');

  static Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Success(null);
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }
}
