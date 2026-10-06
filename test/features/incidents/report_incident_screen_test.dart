import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident_draft.dart';
import 'package:pulseroute/features/incidents/domain/repositories/incident_repository.dart';
import 'package:pulseroute/features/incidents/domain/usecases/incident_usecases.dart';
import 'package:pulseroute/features/incidents/presentation/cubit/report_incident_cubit.dart';
import 'package:pulseroute/features/incidents/presentation/screens/report_incident_screen.dart';

import '../../helpers/incident_builders.dart';

class _MockRepository extends Mock implements IncidentRepository;

class _MockPhotos extends Mock implements PhotoRepository;

void main() {
  late _MockRepository repository;
  late _MockPhotos photos;
  Incident? popped;

  setUpAll(
    () => registerFallbackValue(
      const IncidentDraft(
        category: IncidentCategory.other,
        severity: IncidentSeverity.low,
        location: origin,
      ),
    ),
  );

  setUp(() {
    repository = _MockRepository();
    photos = _MockPhotos();
    popped = null;
  });

  /// Opens the form on top of a home route, so popping can be observed.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.push<Incident>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => ReportIncidentCubit(
                          location: origin,
                          reportIncident: ReportIncident(repository),
                          photos: photos,
                        ),
                        child: const ReportIncidentScreen(),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('choosing "Dark area" turns on the area radius', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('radiusSlider')), findsNothing);

    await tester.tap(find.byKey(const Key('category-darkArea')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('radiusSlider')), findsOneWidget);
    expect(find.text('150 m'), findsOneWidget);
  });

  testWidgets('submits the report and returns the created incident', (
    tester,
  ) async {
    when(() => repository.report(any()))
        .thenAnswer((_) async => Success(incidentAt('new')));
    await pump(tester);

    await tester.tap(find.byKey(const Key('category-dangerousCrossing')));
    await tester.tap(find.text('High'));
    await tester.enterText(
      find.byKey(const Key('descriptionField')),
      'Cars ignore the light',
    );
    await tester.ensureVisible(find.byKey(const Key('submitReport')));
    await tester.tap(find.byKey(const Key('submitReport')));
    await tester.pumpAndSettle();

    final draft =
        verify(() => repository.report(captureAny())).captured.single
            as IncidentDraft;
    expect(draft.category, IncidentCategory.dangerousCrossing);
    expect(draft.severity, IncidentSeverity.high);
    expect(draft.description, 'Cars ignore the light');
    expect(popped?.id, 'new');
  });

  testWidgets('shows the server error and stays on the form', (tester) async {
    when(() => repository.report(any()))
        .thenAnswer((_) async => const Err(NetworkFailure()));
    await pump(tester);

    await tester.ensureVisible(find.byKey(const Key('submitReport')));
    await tester.tap(find.byKey(const Key('submitReport')));
    await tester.pumpAndSettle();

    expect(find.text('You appear to be offline.'), findsOneWidget);
    expect(find.byType(ReportIncidentScreen), findsOneWidget);
    expect(popped, isNull);
  });

  testWidgets('a picked photo is previewed and can be removed', (tester) async {
    // Smallest valid PNG (1x1), so Image.memory can decode it.
    final png = Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, //
      1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68,
      65, 84, 120, 156, 99, 248, 15, 4, 0, 9, 251, 3, 253, 227, 85, 242, 156,
      0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    ]);
    when(() => photos.pick(fromCamera: false))
        .thenAnswer((_) async => Success(png));
    await pump(tester);

    await tester.ensureVisible(find.text('Gallery'));
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byTooltip('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Gallery'), findsOneWidget);
  });
}
