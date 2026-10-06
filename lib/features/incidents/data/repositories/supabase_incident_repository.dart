import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/geo_point.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/ewkt.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_draft.dart';
import '../../domain/repositories/incident_repository.dart';
import '../models/incident_model.dart';

/// [IncidentRepository] backed by Supabase: PostGIS RPCs, Storage for photos
/// and Realtime for live updates.
class SupabaseIncidentRepository implements IncidentRepository {
  SupabaseIncidentRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'incident-photos';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  String _photoUrl(String path) =>
      _client.storage.from(_bucket).getPublicUrl(path);

  @override
  Future<Result<List<Incident>>> nearby(
    GeoPoint center, {
    double radiusM = 3000,
  }) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'incidents_nearby',
        params: {'lat': center.lat, 'lng': center.lng, 'radius_m': radiusM},
      );
      final votes = await _myVotes([
        for (final r in rows) (r as Map<String, dynamic>)['id'] as String,
      ]);
      return Success([
        for (final r in rows.cast<Map<String, dynamic>>())
          IncidentModel.fromJson(
            r,
            photoUrlFor: _photoUrl,
            myVote: votes[r['id']],
          ),
      ]);
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }

  /// The signed-in user's votes for the given incidents (RLS only returns
  /// the user's own rows).
  Future<Map<String, IncidentVote>> _myVotes(List<String> ids) async {
    if (ids.isEmpty || currentUserId == null) return const {};
    final rows = await _client
        .from('incident_votes')
        .select('incident_id, vote')
        .inFilter('incident_id', ids);
    return {
      for (final r in rows)
        r['incident_id'] as String: IncidentModel.voteFromDb(
          r['vote'] as String?,
        )!,
    };
  }

  @override
  Stream<IncidentChange> watchChanges() {
    late final RealtimeChannel channel;
    late final StreamController<IncidentChange> controller;
    controller = StreamController<IncidentChange>(
      onListen: () {
        channel = _client
            .channel('public:incidents')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'incidents',
              callback: (payload) {
                final change = _toChange(payload);
                if (change != null) controller.add(change);
              },
            )
            .subscribe();
      },
      onCancel: () => _client.removeChannel(channel),
    );
    return controller.stream;
  }

  IncidentChange? _toChange(PostgresChangePayload payload) {
    try {
      return switch (payload.eventType) {
        PostgresChangeEvent.delete => IncidentRemoved(
          payload.oldRecord['id'] as String,
        ),
        _ => IncidentUpserted(
          IncidentModel.fromJson(payload.newRecord, photoUrlFor: _photoUrl),
        ),
      };
    } on Object {
      // A malformed payload must never break the live stream.
      return null;
    }
  }

  @override
  Future<Result<Incident>> report(IncidentDraft draft) async {
    final userId = currentUserId;
    if (userId == null) return const Err(AuthFailure('Sign in to report.'));
    try {
      String? photoPath;
      final photo = draft.photo;
      if (photo != null) {
        // Policies only allow writing inside the user's own folder.
        photoPath = '$userId/${const Uuid().v4()}.jpg';
        await _client.storage
            .from(_bucket)
            .uploadBinary(
              photoPath,
              photo,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }
      final row = await _client
          .from('incidents')
          .insert(IncidentModel.toInsertJson(draft, photoPath: photoPath))
          .select()
          .single();
      return Success(IncidentModel.fromJson(row, photoUrlFor: _photoUrl));
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }

  @override
  Future<Result<List<Incident>>> nearRoute({
    required String workoutId,
    required List<GeoPoint> route,
    required bool synced,
    double bufferM = 50,
  }) async {
    final line = Ewkt.lineString(route);
    if (line == null) return const Success([]);
    try {
      final rows = synced
          ? await _client.rpc<List<dynamic>>(
              'incidents_for_workout',
              params: {'workout_id': workoutId, 'buffer_m': bufferM},
            )
          : await _client.rpc<List<dynamic>>(
              'incidents_along_route',
              params: {'route': line, 'buffer_m': bufferM},
            );
      return Success([
        for (final r in rows.cast<Map<String, dynamic>>())
          IncidentModel.fromJson(r, photoUrlFor: _photoUrl),
      ]);
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }

  @override
  Future<Result<void>> vote(String incidentId, IncidentVote vote) async {
    final userId = currentUserId;
    if (userId == null) return const Err(AuthFailure('Sign in to vote.'));
    try {
      // One row per user and incident: voting again changes the vote.
      await _client.from('incident_votes').upsert({
        'incident_id': incidentId,
        'user_id': userId,
        'vote': vote.name,
      }, onConflict: 'incident_id,user_id');
      return const Success(null);
    } on Object catch (error) {
      return Err(mapError(error));
    }
  }
}
