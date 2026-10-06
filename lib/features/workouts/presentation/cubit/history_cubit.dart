import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/time.dart';
import '../../domain/entities/workout_preview.dart';
import '../../domain/usecases/workout_usecases.dart';

enum HistoryStatus { loading, ready }

final class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.loading,
    this.workouts = const [],
    this.thisWeek = const HistoryTotals(
      workouts: 0,
      distanceM: 0,
      duration: Duration.zero,
    ),
    this.refreshing = false,
    this.errorMessage,
  });

  final HistoryStatus status;
  final List<WorkoutPreview> workouts;

  /// Totals since Monday.
  final HistoryTotals thisWeek;
  final bool refreshing;
  final String? errorMessage;

  HistoryState copyWith({
    HistoryStatus? status,
    List<WorkoutPreview>? workouts,
    HistoryTotals? thisWeek,
    bool? refreshing,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      workouts: workouts ?? this.workouts,
      thisWeek: thisWeek ?? this.thisWeek,
      refreshing: refreshing ?? this.refreshing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    workouts,
    thisWeek,
    refreshing,
    errorMessage,
  ];
}

/// The history list: local workouts (offline) plus a manual sync.
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required WatchHistory watchHistory,
    required RefreshHistory refreshHistory,
    required DeleteWorkout deleteWorkout,
    Clock clock = DateTime.now,
  }) : _refreshHistory = refreshHistory,
       _deleteWorkout = deleteWorkout,
       _clock = clock,
       super(const HistoryState()) {
    _subscription = watchHistory().listen(_onHistory);
  }

  final RefreshHistory _refreshHistory;
  final DeleteWorkout _deleteWorkout;
  final Clock _clock;
  late final StreamSubscription<List<WorkoutPreview>> _subscription;

  void _onHistory(List<WorkoutPreview> workouts) {
    final now = _clock();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    emit(
      state.copyWith(
        status: HistoryStatus.ready,
        workouts: workouts,
        thisWeek: HistoryTotals.since(workouts, monday),
      ),
    );
  }

  /// Uploads pending workouts and imports ones from other devices.
  Future<void> refresh() async {
    if (state.refreshing) return;
    emit(state.copyWith(refreshing: true));
    final result = await _refreshHistory();
    emit(
      state.copyWith(
        refreshing: false,
        errorMessage: result.failureOrNull?.message,
      ),
    );
  }

  Future<void> delete(String id) async {
    final result = await _deleteWorkout(id);
    if (result.failureOrNull case final failure?) {
      emit(state.copyWith(errorMessage: failure.message));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
