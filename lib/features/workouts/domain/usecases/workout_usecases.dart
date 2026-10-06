import '../../../../core/errors/result.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/domain/repositories/incident_repository.dart';
import '../entities/workout.dart';
import '../entities/workout_preview.dart';
import '../repositories/workout_repository.dart';
import '../repositories/workout_sync_repository.dart';

/// Live history list.
class WatchHistory {
  const WatchHistory(this._repository);

  final WorkoutRepository _repository;

  Stream<List<WorkoutPreview>> call() => _repository.watchHistory();
}

/// Two-way refresh: uploads pending workouts, then imports server ones.
class RefreshHistory {
  const RefreshHistory(this._repository, this._sync);

  final WorkoutRepository _repository;
  final WorkoutSyncRepository _sync;

  Future<Result<int>> call() async {
    final uploaded = await _sync.syncPending();
    if (uploaded.failureOrNull case final failure?) return Err(failure);
    return await _repository.refreshFromServer();
  }
}

class GetWorkout {
  const GetWorkout(this._repository);

  final WorkoutRepository _repository;

  Future<Result<Workout>> call(String id) => _repository.getWorkout(id);
}

class DeleteWorkout {
  const DeleteWorkout(this._repository);

  final WorkoutRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}

/// Community incidents that were near the route of a workout.
class GetIncidentsNearWorkout {
  const GetIncidentsNearWorkout(this._incidents);

  final IncidentRepository _incidents;

  Future<Result<List<Incident>>> call(Workout workout) => _incidents.nearRoute(
    workoutId: workout.id,
    route: workout.route,
    synced: workout.synced,
  );
}
