import 'package:flutter_test/flutter_test.dart';
import 'package:pulseroute/core/env/app_env.dart';

void main() {
  test('reports every missing key', () {
    const env = AppEnv(supabaseUrl: '', supabaseAnonKey: '', mapsApiKey: '');

    expect(env.missingKeys, [
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'MAPS_API_KEY',
    ]);
    expect(env.isComplete, isFalse);
    expect(env.hasBackend, isFalse);
  });

  test('backend is available without a Maps key', () {
    const env = AppEnv(
      supabaseUrl: 'https://x.supabase.co',
      supabaseAnonKey: 'anon',
      mapsApiKey: '',
    );

    expect(env.hasBackend, isTrue);
    expect(env.missingKeys, ['MAPS_API_KEY']);
  });
}
