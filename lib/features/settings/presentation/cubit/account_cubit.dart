import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/form_status.dart';
import '../../../auth/domain/usecases/auth_usecases.dart';

/// State of the "delete account" action.
typedef AccountState = ({FormStatus status, String? error});

/// Deletes the account. On success the auth listener signs the user out
/// and the router returns to the sign in screen.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._deleteAccount)
    : super((status: FormStatus.idle, error: null));

  final DeleteAccount _deleteAccount;

  Future<void> deleteAccount() async {
    if (state.status.isSubmitting) return;
    emit((status: FormStatus.submitting, error: null));
    final result = await _deleteAccount();
    emit(
      result.fold(
        (_) => (status: FormStatus.success, error: null),
        (f) => (status: FormStatus.failure, error: f.message),
      ),
    );
  }
}
