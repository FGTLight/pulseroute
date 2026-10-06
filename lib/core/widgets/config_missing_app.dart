import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown instead of the app when it was built without the required keys,
/// so a missing `.env` is obvious instead of failing deep inside Supabase.
class ConfigMissingApp extends StatelessWidget {
  const ConfigMissingApp({required this.missingKeys, super.key});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          return Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.key_off_rounded, size: 48),
                  const SizedBox(height: 16),
                  Text('Configuration missing', style: textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const Text('PulseRoute was built without these values:'),
                  const SizedBox(height: 8),
                  for (final key in missingKeys)
                    Text('• $key', style: textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  const Text(
                    'Copy .env.example to .env, fill it in and run:\n\n'
                    'flutter run --dart-define-from-file=.env',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
