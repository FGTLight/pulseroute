import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/features/settings/domain/settings_repository.dart';
import 'package:pulseroute/features/settings/presentation/cubit/theme_cubit.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository;

void main() {
  late _MockSettingsRepository repository;

  setUp(() {
    repository = _MockSettingsRepository();
    when(() => repository.themeMode).thenReturn(ThemeMode.system);
    when(() => repository.setThemeMode(any())).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(ThemeMode.system));

  test('starts with the persisted theme', () {
    when(() => repository.themeMode).thenReturn(ThemeMode.dark);
    expect(ThemeCubit(repository).state, ThemeMode.dark);
  });

  blocTest<ThemeCubit, ThemeMode>(
    'emits and persists the new theme',
    build: () => ThemeCubit(repository),
    act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
    expect: () => [ThemeMode.dark],
    verify: (_) => verify(() => repository.setThemeMode(ThemeMode.dark)),
  );

  blocTest<ThemeCubit, ThemeMode>(
    'ignores selecting the current theme',
    build: () => ThemeCubit(repository),
    act: (cubit) => cubit.setThemeMode(ThemeMode.system),
    expect: () => <ThemeMode>[],
    verify: (_) => verifyNever(() => repository.setThemeMode(any())),
  );
}
