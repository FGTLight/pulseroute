/// Route paths, kept in one place to avoid typos.
abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  static const track = '/track';
  static const incidents = '/incidents';
  static const history = '/history';
  static const settings = '/settings';
  static const profile = '/settings/profile';

  /// Routes reachable without an account.
  static const Set<String> public = {signIn, signUp};
}
