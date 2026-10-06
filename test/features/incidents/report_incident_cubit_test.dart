import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/core/utils/form_status.dart';
import 'package:pulseroute/features/incidents/data/models/incident_model.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident_draft.dart';
import 'package:pulseroute/features/incidents/domain/repositories/incident_repository.dart';
import 'package:pulseroute/features/incidents/domain/usecases/incident_usecases.dart';
import 'package:pulseroute/features/incidents/presentation/cubit/report_incident_cubit.dart';

import '../../helpers/incident_builders.dart';

class _MockRepository extends Mock implements IncidentRepository;

class _MockPhotos extends Mock implements PhotoRepository;

void main() {
  late _MockRepository repository;
  late _MockPhotos photos;

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
  });

  ReportIncidentCubit build() => ReportIncidentCubit(
    location: origin,
    reportIncident: ReportIncident(repository),
    photos: photos,
  );

  test('area categories default to a circle, point categories do not', () {
    final cubit = build()..selectCategory(IncidentCategory.darkArea);
    expect(cubit.state.radiusM, 150);

    cubit.selectCategory(IncidentCategory.pothole);
    expect(cubit.state.isArea, isFalse);

    cubit
      ..setArea(enabled: true)
      ..setRadius(10_000);
    expect(cubit.state.radiusM, IncidentDraft.maxRadiusM);
  });

  blocTest<ReportIncidentCubit, ReportIncidentState>(
    'attaches a photo and submits the draft',
    setUp: () {
      when(() => photos.pick(fromCamera: true))
          .thenAnswer((_) async => Success(Uint8List.fromList([1, 2, 3])));
      when(() => repository.report(any()))
          .thenAnswer((_) async => Success(incidentAt('new')));
    },
    build: build,
    act: (cubit) async {
      cubit.selectCategory(IncidentCategory.darkArea);
      await cubit.pickPhoto(fromCamera: true);
      await cubit.submit(description: '  No lights on the path  ');
    },
    verify: (cubit) {
      expect(cubit.state.status, FormStatus.success);
      final draft =
          verify(() => repository.report(captureAny())).captured.single
              as IncidentDraft;
      expect(draft.category, IncidentCategory.darkArea);
      expect(draft.radiusM, 150);
      expect(draft.photo, hasLength(3));
      expect(draft.description, '  No lights on the path  ');
    },
  );

  blocTest<ReportIncidentCubit, ReportIncidentState>(
    'rejects descriptions that are too long without calling the backend',
    build: build,
    act: (cubit) => cubit.submit(description: 'x' * 300),
    skip: 1,
    expect: () => [
      isA<ReportIncidentState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having(
            (s) => s.errorMessage,
            'error',
            'Keep the description under 280 characters',
          ),
    ],
    verify: (_) => verifyNever(() => repository.report(any())),
  );

  blocTest<ReportIncidentCubit, ReportIncidentState>(
    'explains a denied camera permission',
    setUp: () => when(() => photos.pick(fromCamera: true)).thenAnswer(
      (_) async => const Err(PermissionFailure('Camera access is needed.')),
    ),
    build: build,
    act: (cubit) => cubit.pickPhoto(fromCamera: true),
    skip: 1,
    expect: () => [
      isA<ReportIncidentState>()
          .having((s) => s.pickingPhoto, 'picking', false)
          .having((s) => s.errorMessage, 'error', 'Camera access is needed.'),
    ],
  );

  group('IncidentModel', () {
    test('maps categories to Postgres enum values and back', () {
      expect(
        IncidentModel.categoryToDb(IncidentCategory.dangerousCrossing),
        'dangerous_crossing',
      );
      for (final c in IncidentCategory.values) {
        expect(IncidentModel.categoryFromDb(IncidentModel.categoryToDb(c)), c);
      }
    });

    test('parses an RPC / Realtime row', () {
      final incident = IncidentModel.fromJson({
        'id': 'i1',
        'reporter_id': null,
        'category': 'dark_area',
        'severity': 3,
        'description': 'Dark',
        'lat': -30.04,
        'lng': -51.24,
        'radius_m': 180,
        'photo_path': 'u1/p.jpg',
        'status': 'active',
        'confirmations': 6,
        'resolutions': 0,
        'created_at': '2026-10-03T12:00:00Z',
        'expires_at': '2026-10-17T12:00:00Z',
      }, photoUrlFor: (p) => 'https://cdn/$p');

      expect(incident.category, IncidentCategory.darkArea);
      expect(incident.severity, IncidentSeverity.high);
      expect(incident.isArea, isTrue);
      expect(incident.photoUrl, 'https://cdn/u1/p.jpg');
    });

    test('builds the insert row with an EWKT point (lng lat)', () {
      final row = IncidentModel.toInsertJson(
        const IncidentDraft(
          category: IncidentCategory.pothole,
          severity: IncidentSeverity.high,
          location: origin,
          description: ' Big hole ',
        ),
      );
      expect(row['location'], 'SRID=4326;POINT(-51.2405 -30.0391)');
      expect(row['category'], 'pothole');
      expect(row['severity'], 3);
      expect(row['description'], 'Big hole');
    });
  });
}
