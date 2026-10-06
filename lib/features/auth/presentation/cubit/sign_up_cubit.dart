import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/activity_type.dart';
import '../../../../core/utils/form_status.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

/// State of the sign-up form.
final class SignUpState extends Equatable {
  const SignUpState({
    this.activity = ActivityType.run,
    this.status = FormStatus.idle,
    this.outcome,
    this.errorMessage,
  });

  final ActivityType activity;
  final FormStatus status;

  /// Set on success: tells the UI whether to wait for email confirmation.
  final SignUpOutcome? outcome;
  final String? errorMessage;

  SignUpState copyWith({
    ActivityType? activity,
    FormStatus? status,
    SignUpOutcome? outcome,
    String? errorMessage,
  }) {
    return SignUpState(
      activity: activity ?? this.activity,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [activity, status, outcome, errorMessage];
}

/// Creates an account with a display name and preferred activity.
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({required SignUpWithEmail signUp})
    : _signUp = signUp,
      super(const SignUpState());

  final SignUpWithEmail _signUp;

  void selectActivity(ActivityType activity) =>
      emit(state.copyWith(activity: activity));

  Future<void> submit({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (state.status.isSubmitting) return;
    emit(state.copyWith(status: FormStatus.submitting));

    final result = await _signUp(
      email: email,
      password: password,
      displayName: displayName,
      preferredActivity: state.activity,
    );
    emit(
      result.fold(
        (outcome) =>
            state.copyWith(status: FormStatus.success, outcome: outcome),
        (f) =>
            state.copyWith(status: FormStatus.failure, errorMessage: f.message),
      ),
    );
  }
}
