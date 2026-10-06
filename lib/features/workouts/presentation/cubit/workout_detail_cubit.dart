import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../incidents/domain/entities/incident.dart';
import '../../domain/entities/workout.dart';
import '../../domain/usecases/workout_usecases.dart';

enum WorkoutDetailStatus { loading, ready, failure }

final class WorkoutDetailState extends Equatable {
  const WorkoutDetailState({
    this.status = WorkoutDetailStatus.loading,
    this.workout,
    this.incidents,
    this.incidentsError,
    this.errorMessage,
  });

  final WorkoutDetailStatus status;
  final Workout? workout;

  /// `null` while loading. Loaded after the workout, from the server.
  final List<Incident>? incidents;

  /// Why incidents could not be loaded (e.g. offline). The workout itself
  /// is still shown, since it lives on the device.
  final String? incidentsError;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    status,
    workout,
    incidents,
    incidentsError,
    errorMessage,
  ];
}

/// A workout with its full route and the incidents that were near it.
class WorkoutDetailCubit extends Cubit<WorkoutDetailState> {
  WorkoutDetailCubit({
    required GetWorkout getWorkout,
    required GetIncidentsNearWorkout getIncidents,
  }) : _getWorkout = getWorkout,
       _getIncidents = getIncidents,
       super(const WorkoutDetailState());

  final GetWorkout _getWorkout;
  final GetIncidentsNearWorkout _getIncidents;

  Future<void> load(String id) async {
    emit(const WorkoutDetailState());
    final result = await _getWorkout(id);
    final workout = result.valueOrNull;
    if (workout == null) {
      emit(
        WorkoutDetailState(
          status: WorkoutDetailStatus.failure,
          errorMessage: result.failureOrNull?.message,
        ),
      );
      return;
    }
    emit(
      WorkoutDetailState(status: WorkoutDetailStatus.ready, workout: workout),
    );

    final incidents = await _getIncidents(workout);
    emit(
      WorkoutDetailState(
        status: WorkoutDetailStatus.ready,
        workout: workout,
        incidents: incidents.valueOrNull ?? const [],
        incidentsError: incidents.failureOrNull?.message,
      ),
    );
  }
}
