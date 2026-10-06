/// Route paths, kept in one place to avoid typos.
abstract final class AppRoutes {
  static const onboarding = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  static const track = '/track';
  static const workoutSummary = '/track/summary';
  static const incidents = '/incidents';
  static const reportIncident = '/incidents/report';
  static const history = '/history';
  static const settings = '/settings';
  static const profile = '/settings/profile';

  static String workoutDetail(String id) => '/history/$id';

  /// Routes reachable without an account.
  static const Set<String> public = {onboarding, signIn, signUp};
}
