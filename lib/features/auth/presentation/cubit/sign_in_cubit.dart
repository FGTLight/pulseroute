import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/form_status.dart';
import '../../domain/usecases/auth_usecases.dart';

/// How the user signs in.
enum SignInMethod { password, magicLink }

/// State of the sign-in form.
final class SignInState extends Equatable {
  const SignInState({
    this.method = SignInMethod.password,
    this.status = FormStatus.idle,
    this.errorMessage,
    this.magicLinkSentTo,
  });

  final SignInMethod method;
  final FormStatus status;
  final String? errorMessage;

  /// Email the magic link was sent to, once sent.
  final String? magicLinkSentTo;

  SignInState copyWith({
    SignInMethod? method,
    FormStatus? status,
    String? errorMessage,
    String? magicLinkSentTo,
  }) {
    return SignInState(
      method: method ?? this.method,
      status: status ?? this.status,
      errorMessage: errorMessage,
      magicLinkSentTo: magicLinkSentTo ?? this.magicLinkSentTo,
    );
  }

  @override
  List<Object?> get props => [method, status, errorMessage, magicLinkSentTo];
}

/// Signs in with a password or by emailing a magic link.
///
/// A successful password sign-in is picked up by `SessionBloc`, which makes
/// the router leave the auth screens; this cubit only reports progress.
class SignInCubit extends Cubit<SignInState> {
  SignInCubit({
    required SignInWithPassword signInWithPassword,
    required SendMagicLink sendMagicLink,
  }) : _signInWithPassword = signInWithPassword,
       _sendMagicLink = sendMagicLink,
       super(const SignInState());

  final SignInWithPassword _signInWithPassword;
  final SendMagicLink _sendMagicLink;

  void selectMethod(SignInMethod method) => emit(SignInState(method: method));

  Future<void> submit({required String email, String password = ''}) async {
    if (state.status.isSubmitting) return;
    emit(state.copyWith(status: FormStatus.submitting));

    if (state.method == SignInMethod.password) {
      final result = await _signInWithPassword(
        email: email,
        password: password,
      );
      emit(
        result.fold(
          (_) => state.copyWith(status: FormStatus.success),
          (f) => state.copyWith(
            status: FormStatus.failure,
            errorMessage: f.message,
          ),
        ),
      );
    } else {
      final result = await _sendMagicLink(email: email);
      emit(
        result.fold(
          (_) => state.copyWith(
            status: FormStatus.success,
            magicLinkSentTo: email.trim(),
          ),
          (f) => state.copyWith(
            status: FormStatus.failure,
            errorMessage: f.message,
          ),
        ),
      );
    }
  }
}
