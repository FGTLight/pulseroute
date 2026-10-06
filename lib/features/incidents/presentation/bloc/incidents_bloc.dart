import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../../core/utils/time.dart';
import '../../domain/entities/incident.dart';
import '../../domain/repositories/incident_repository.dart';
import '../../domain/usecases/incident_usecases.dart';

// Events ---------------------------------------------------------------------

sealed class IncidentsEvent extends Equatable {
  const IncidentsEvent();

  @override
  List<Object?> get props => [];
}

/// First load: centers on the user, or on the demo city without location.
final class IncidentsStarted extends IncidentsEvent {
  const IncidentsStarted();
}

/// The user's position (or the map center) changed.
final class IncidentsAreaChanged extends IncidentsEvent {
  const IncidentsAreaChanged(this.center);

  final GeoPoint center;

  @override
  List<Object?> get props => [center];
}

final class IncidentsRefreshRequested extends IncidentsEvent {
  const IncidentsRefreshRequested();
}

/// A report created on this device (shown before Realtime echoes it).
final class IncidentAdded extends IncidentsEvent {
  const IncidentAdded(this.incident);

  final Incident incident;

  @override
  List<Object?> get props => [incident];
}

final class IncidentVoteRequested extends IncidentsEvent {
  const IncidentVoteRequested(this.incident, this.vote);

  final Incident incident;
  final IncidentVote vote;

  @override
  List<Object?> get props => [incident, vote];
}

final class _IncidentsChangeReceived extends IncidentsEvent {
  const _IncidentsChangeReceived(this.change);

  final IncidentChange change;

  @override
  List<Object?> get props => [change];
}

// State ----------------------------------------------------------------------

enum IncidentsStatus { initial, loading, ready, failure }

final class IncidentsState extends Equatable {
  const IncidentsState({
    this.status = IncidentsStatus.initial,
    this.byId = const {},
    this.center,
    this.errorMessage,
  });

  final IncidentsStatus status;
  final Map<String, Incident> byId;

  /// Where the current list was loaded around.
  final GeoPoint? center;
  final String? errorMessage;

  /// Incidents sorted by distance from [center].
  List<Incident> get incidents {
    final list = byId.values.toList();
    final c = center;
    if (c != null) {
      list.sort(
        (a, b) => GeoMath.distance(
          c,
          a.location,
        ).compareTo(GeoMath.distance(c, b.location)),
      );
    }
    return list;
  }

  IncidentsState copyWith({
    IncidentsStatus? status,
    Map<String, Incident>? byId,
    GeoPoint? center,
    String? errorMessage,
  }) {
    return IncidentsState(
      status: status ?? this.status,
      byId: byId ?? this.byId,
      center: center ?? this.center,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, byId, center, errorMessage];
}

// Bloc -----------------------------------------------------------------------

/// Nearby incidents, kept fresh with Realtime and updated optimistically
/// when the user votes.
class IncidentsBloc extends Bloc<IncidentsEvent, IncidentsState> {
  IncidentsBloc({
    required GetNearbyIncidents getNearby,
    required VoteOnIncident vote,
    required IncidentRepository repository,
    required Future<GeoPoint?> Function() locate,
    Clock clock = DateTime.now,
  }) : _getNearby = getNearby,
       _vote = vote,
       _repository = repository,
       _locate = locate,
       _clock = clock,
       super(const IncidentsState()) {
    on<IncidentsStarted>(_onStarted);
    on<IncidentsAreaChanged>(_onAreaChanged);
    on<IncidentsRefreshRequested>(_onRefreshRequested);
    on<IncidentAdded>(
      (event, emit) => emit(_withUpsert(state, event.incident)),
    );
    on<IncidentVoteRequested>(_onVoteRequested);
    on<_IncidentsChangeReceived>(_onChangeReceived);
  }

  final GetNearbyIncidents _getNearby;
  final VoteOnIncident _vote;
  final IncidentRepository _repository;
  final Future<GeoPoint?> Function() _locate;
  final Clock _clock;
  StreamSubscription<IncidentChange>? _changes;

  /// Reload when the user moves this far from where the list was loaded.
  static const reloadDistanceM = 1000.0;

  /// Used when the position is unknown: Porto Alegre, the seed data city.
  static const fallbackCenter = GeoPoint(-30.0346, -51.2177);

  Future<void> _onStarted(
    IncidentsStarted event,
    Emitter<IncidentsState> emit,
  ) async {
    if (state.status != IncidentsStatus.initial) return;
    emit(state.copyWith(status: IncidentsStatus.loading));
    await _load(await _locate() ?? fallbackCenter, emit);
  }

  Future<void> _onAreaChanged(
    IncidentsAreaChanged event,
    Emitter<IncidentsState> emit,
  ) async {
    final loadedAt = state.center;
    final moved = loadedAt == null
        ? double.infinity
        : GeoMath.distance(loadedAt, event.center);
    if (state.status == IncidentsStatus.loading) return;
    if (state.status == IncidentsStatus.ready && moved < reloadDistanceM) {
      return;
    }
    await _load(event.center, emit);
  }

  Future<void> _onRefreshRequested(
    IncidentsRefreshRequested event,
    Emitter<IncidentsState> emit,
  ) async {
    final center = state.center;
    if (center != null) await _load(center, emit);
  }

  Future<void> _load(GeoPoint center, Emitter<IncidentsState> emit) async {
    emit(state.copyWith(status: IncidentsStatus.loading, center: center));
    _changes ??= _repository.watchChanges().listen(
      (change) => add(_IncidentsChangeReceived(change)),
    );

    final result = await _getNearby(center);
    emit(
      result.fold(
        (list) => state.copyWith(
          status: IncidentsStatus.ready,
          byId: {for (final i in list) i.id: i},
        ),
        (failure) => state.copyWith(
          status: IncidentsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
    );
  }

  Future<void> _onVoteRequested(
    IncidentVoteRequested event,
    Emitter<IncidentsState> emit,
  ) async {
    final before = state.byId[event.incident.id] ?? event.incident;
    if (before.myVote == event.vote) return;

    // Optimistic update: the server trigger will send the real counters
    // through Realtime a moment later.
    emit(_withUpsert(state, _applyVote(before, event.vote)));

    final result = await _vote(before, event.vote);
    if (result.failureOrNull case final failure?) {
      emit(_withUpsert(state, before).copyWith(errorMessage: failure.message));
    }
  }

  void _onChangeReceived(
    _IncidentsChangeReceived event,
    Emitter<IncidentsState> emit,
  ) {
    switch (event.change) {
      case IncidentRemoved(:final id):
        if (!state.byId.containsKey(id)) return;
        emit(state.copyWith(byId: Map.of(state.byId)..remove(id)));
      case IncidentUpserted(:final incident):
        final existing = state.byId[incident.id];
        final center = state.center;
        // Ignore far away reports we were not showing anyway.
        if (existing == null &&
            center != null &&
            GeoMath.distance(center, incident.location) >
                GetNearbyIncidents.defaultRadiusM) {
          return;
        }
        // Realtime rows do not include the user's vote: keep ours.
        emit(_withUpsert(state, incident.copyWith(myVote: existing?.myVote)));
    }
  }

  /// Adds or replaces [incident], dropping it once resolved or expired.
  IncidentsState _withUpsert(IncidentsState s, Incident incident) {
    final byId = Map.of(s.byId);
    if (incident.isLive(_clock())) {
      byId[incident.id] = incident;
    } else {
      byId.remove(incident.id);
    }
    return s.copyWith(byId: byId);
  }

  static Incident _applyVote(Incident i, IncidentVote vote) {
    var confirmations = i.confirmations;
    var resolutions = i.resolutions;
    // Changing a vote moves it from one counter to the other.
    if (i.myVote == IncidentVote.confirm) confirmations--;
    if (i.myVote == IncidentVote.resolve) resolutions--;
    if (vote == IncidentVote.confirm) confirmations++;
    if (vote == IncidentVote.resolve) resolutions++;
    return i.copyWith(
      confirmations: confirmations,
      resolutions: resolutions,
      myVote: vote,
    );
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    await super.close();
  }
}
