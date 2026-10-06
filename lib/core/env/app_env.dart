import 'package:meta/meta.dart';

/// Runtime configuration injected at build time with `--dart-define` or
/// `--dart-define-from-file=.env`. Keys are never hardcoded in the repo.
@immutable
class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.mapsApiKey,
  });

  /// Reads the values compiled into the app.
  factory AppEnv.fromEnvironment() => const AppEnv(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    mapsApiKey: String.fromEnvironment('MAPS_API_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Only checked for presence: the native Maps SDK reads it from the
  /// Android manifest / iOS Info.plist, not from Dart.
  final String mapsApiKey;

  /// Names of the variables that are empty.
  List<String> get missingKeys => [
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    if (mapsApiKey.isEmpty) 'MAPS_API_KEY',
  ];

  /// Whether the backend can be reached (Supabase URL and key are set).
  bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  bool get isComplete => missingKeys.isEmpty;
}
