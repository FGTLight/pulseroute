import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulseroute/core/domain/geo_point.dart';
import 'package:pulseroute/core/errors/failures.dart';
import 'package:pulseroute/core/errors/result.dart';
import 'package:pulseroute/features/incidents/domain/entities/incident.dart';
import 'package:pulseroute/features/incidents/domain/repositories/incident_repository.dart';
import 'package:pulseroute/features/incidents/domain/usecases/incident_usecases.dart';
import 'package:pulseroute/features/incidents/presentation/bloc/incidents_bloc.dart';

import '../../helpers/incident_builders.dart';

class _MockRepository extends Mock implements IncidentRepository;

void main() {
  late _MockRepository repository;
  late StreamController<IncidentChange> changes;

  setUpAll(() {
    registerFallbackValue(origin);
    registerFallbackValue(IncidentVote.confirm);
  });

  setUp(() {
    repository = _MockRepository();
    changes = StreamController<IncidentChange>.broadcast();
    when(() => repository.watchChanges()).thenAnswer((_) => changes.stream);
    when(() => repository.currentUserId).thenReturn('me');
    when(() => repository.nearby(any(), radiusM: any(named: 'radiusM')))
        .thenAnswer(
          (_) async => Success([
            incidentAt('far', metersNorth: 800),
            incidentAt('near', metersNorth: 50, confirmations: 2),
          ]),
        );
  });

  tearDown(() => changes.close());

  IncidentsBloc build() => IncidentsBloc(
    getNearby: GetNearbyIncidents(repository),
    vote: VoteOnIncident(repository),
    repository: repository,
    locate: () async => origin,
    clock: () => incidentNow,
  );

  Future<IncidentsBloc> loaded() async {
    final bloc = build()..add(const IncidentsAreaChanged(origin));
    await pumpEventQueue();
    return bloc;
  }

  group('loading', () {
    test('starts around the user position', () async {
      final bloc = build()..add(const IncidentsStarted());
      await pumpEventQueue();
      expect(bloc.state.center, origin);
      expect(bloc.state.status, IncidentsStatus.ready);
      await bloc.close();
    });

    test('falls back to the demo city without location', () async {
      final bloc = IncidentsBloc(
        getNearby: GetNearbyIncidents(repository),
        vote: VoteOnIncident(repository),
        repository: repository,
        locate: () async => null,
      )..add(const IncidentsStarted());
      await pumpEventQueue();
      expect(bloc.state.center, IncidentsBloc.fallbackCenter);
      await bloc.close();
    });

    blocTest<IncidentsBloc, IncidentsState>(
      'loads nearby incidents sorted by distance',
      build: build,
      act: (bloc) => bloc.add(const IncidentsAreaChanged(origin)),
      expect: () => [
        isA<IncidentsState>().having(
          (s) => s.status,
          'status',
          IncidentsStatus.loading,
        ),
        isA<IncidentsState>()
            .having((s) => s.status, 'status', IncidentsStatus.ready)
            .having((s) => s.incidents.map((i) => i.id), 'ids', [
              'near',
              'far',
            ]),
      ],
    );

    test('does not reload for small moves, but does after 1 km', () async {
      final bloc = await loaded();

      bloc.add(IncidentsAreaChanged(GeoPoint(origin.lat + 0.002, origin.lng)));
      await pumpEventQueue();
      verify(() => repository.nearby(any(), radiusM: any(named: 'radiusM')))
          .called(1);

      bloc.add(IncidentsAreaChanged(GeoPoint(origin.lat + 0.02, origin.lng)));
      await pumpEventQueue();
      verify(() => repository.nearby(any(), radiusM: any(named: 'radiusM')))
          .called(1);
      await bloc.close();
    });

    blocTest<IncidentsBloc, IncidentsState>(
      'reports load failures',
      setUp: () =>
          when(() => repository.nearby(any(), radiusM: any(named: 'radiusM')))
              .thenAnswer((_) async => const Err(NetworkFailure())),
      build: build,
      act: (bloc) => bloc.add(const IncidentsAreaChanged(origin)),
      skip: 1,
      expect: () => [
        isA<IncidentsState>()
            .having((s) => s.status, 'status', IncidentsStatus.failure)
            .having(
              (s) => s.errorMessage,
              'error',
              'You appear to be offline.',
            ),
      ],
    );
  });

  group('realtime', () {
    test('new nearby reports appear without refreshing', () async {
      final bloc = await loaded();

      changes.add(IncidentUpserted(incidentAt('new', metersNorth: 100)));
      await pumpEventQueue();

      expect(bloc.state.byId.keys, contains('new'));
      await bloc.close();
    });

    test('far away reports are ignored', () async {
      final bloc = await loaded();

      changes.add(
        IncidentUpserted(incidentAt('other-city', metersNorth: 9000)),
      );
      await pumpEventQueue();

      expect(bloc.state.byId.keys, isNot(contains('other-city')));
      await bloc.close();
    });

    test('updates keep my vote; resolved and deleted ones disappear', () async {
      when(() => repository.nearby(any(), radiusM: any(named: 'radiusM')))
          .thenAnswer(
            (_) async => Success([
              incidentAt('a', myVote: IncidentVote.confirm, confirmations: 1),
              incidentAt('b', metersNorth: 30),
              incidentAt('c', metersNorth: 60),
            ]),
          );
      final bloc = await loaded();

      changes
        ..add(IncidentUpserted(incidentAt('a', confirmations: 5)))
        ..add(
          IncidentUpserted(
            incidentAt('b', metersNorth: 30, status: IncidentStatus.resolved),
          ),
        )
        ..add(const IncidentRemoved('c'));
      await pumpEventQueue();

      expect(bloc.state.byId['a']!.confirmations, 5);
      expect(bloc.state.byId['a']!.myVote, IncidentVote.confirm);
      expect(bloc.state.byId.keys, ['a']);
      await bloc.close();
    });
  });

  group('voting', () {
    test('confirming updates the counter immediately', () async {
      when(() => repository.vote(any(), any()))
          .thenAnswer((_) async => const Success(null));
      final bloc = await loaded();
      final near = bloc.state.byId['near']!;

      bloc.add(IncidentVoteRequested(near, IncidentVote.confirm));
      await pumpEventQueue();

      expect(bloc.state.byId['near']!.confirmations, 3);
      expect(bloc.state.byId['near']!.myVote, IncidentVote.confirm);
      verify(() => repository.vote('near', IncidentVote.confirm)).called(1);
      await bloc.close();
    });

    test('changing a vote moves it between counters', () async {
      when(() => repository.vote(any(), any()))
          .thenAnswer((_) async => const Success(null));
      when(() => repository.nearby(any(), radiusM: any(named: 'radiusM')))
          .thenAnswer(
            (_) async => Success([
              incidentAt('a', confirmations: 2, myVote: IncidentVote.confirm),
            ]),
          );
      final bloc = await loaded();

      bloc.add(
        IncidentVoteRequested(bloc.state.byId['a']!, IncidentVote.resolve),
      );
      await pumpEventQueue();

      expect(bloc.state.byId['a']!.confirmations, 1);
      expect(bloc.state.byId['a']!.resolutions, 1);
      await bloc.close();
    });

    test('a failed vote is rolled back with a message', () async {
      when(() => repository.vote(any(), any()))
          .thenAnswer((_) async => const Err(NetworkFailure()));
      final bloc = await loaded();
      final near = bloc.state.byId['near']!;

      bloc.add(IncidentVoteRequested(near, IncidentVote.confirm));
      await pumpEventQueue();

      expect(bloc.state.byId['near'], near);
      expect(bloc.state.errorMessage, 'You appear to be offline.');
      await bloc.close();
    });

    test('reporters cannot confirm their own incident', () async {
      when(() => repository.nearby(any(), radiusM: any(named: 'radiusM')))
          .thenAnswer(
            (_) async => Success([incidentAt('mine', reporterId: 'me')]),
          );
      final bloc = await loaded();

      bloc.add(
        IncidentVoteRequested(bloc.state.byId['mine']!, IncidentVote.confirm),
      );
      await pumpEventQueue();

      expect(bloc.state.byId['mine']!.confirmations, 0);
      expect(bloc.state.errorMessage, 'You cannot confirm your own report.');
      verifyNever(() => repository.vote(any(), any()));
      await bloc.close();
    });
  });
}
