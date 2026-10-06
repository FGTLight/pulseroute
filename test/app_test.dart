import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/app.dart';
import 'package:pulseroute/features/settings/domain/settings_repository.dart';
import 'package:pulseroute/features/settings/presentation/cubit/theme_cubit.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository;

void main() {
  late ThemeCubit themeCubit;

  setUp(() {
    final repository = _MockSettingsRepository();
    when(() => repository.themeMode).thenReturn(ThemeMode.light);
    when(() => repository.setThemeMode(ThemeMode.dark))
        .thenAnswer((_) async {});
    themeCubit = ThemeCubit(repository);
  });

  tearDown(() => themeCubit.close());

  testWidgets('opens on the Track tab and switches tabs', (tester) async {
    await tester.pumpWidget(PulseRouteApp(themeCubit: themeCubit));
    await tester.pumpAndSettle();

    expect(find.text('Ready when you are'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No workouts yet'), findsOneWidget);
  });

  testWidgets('changing the theme in Settings updates the app', (tester) async {
    await tester.pumpWidget(PulseRouteApp(themeCubit: themeCubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
