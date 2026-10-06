import 'package:meta/meta.dart';

/// Runtime configuration injected at build time with `--dart-define` or
/// `--dart-define-from-file=.env`. Keys are never hardcoded in the repo.
@immutable
class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabaseKey,
    required this.mapsApiKey,
  });

  /// Reads the values compiled into the app.
  ///
  /// Accepts Supabase's new publishable key or the legacy anon key.
  factory AppEnv.fromEnvironment() {
    const publishable = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const anon = String.fromEnvironment('SUPABASE_ANON_KEY');
    return AppEnv(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseKey: publishable.isNotEmpty ? publishable : anon,
      mapsApiKey: const String.fromEnvironment('MAPS_API_KEY'),
    );
  }

  final String supabaseUrl;

  /// Public client key (publishable or anon). Safe to ship in the app:
  /// Row Level Security protects the data.
  final String supabaseKey;

  /// Only checked for presence: the native Maps SDK reads it from the
  /// Android manifest / iOS Info.plist, not from Dart.
  final String mapsApiKey;

  /// Names of the variables that are empty.
  List<String> get missingKeys => [
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabaseKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    if (mapsApiKey.isEmpty) 'MAPS_API_KEY',
  ];

  /// Whether the backend can be reached (Supabase URL and key are set).
  bool get hasBackend => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  bool get isComplete => missingKeys.isEmpty;
}
