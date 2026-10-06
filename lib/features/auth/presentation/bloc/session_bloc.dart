import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// Events ---------------------------------------------------------------------

/// Inputs of [SessionBloc].
sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

/// The auth provider reported a new user (or `null` after signing out).
final class SessionUserChanged extends SessionEvent {
  const SessionUserChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}

/// The user asked to sign out.
final class SessionSignOutRequested extends SessionEvent {
  const SessionSignOutRequested();
}

// State ----------------------------------------------------------------------

/// Who is signed in. Drives the router's auth redirects.
final class SessionState extends Equatable {
  const SessionState.authenticated(AppUser this.user);

  const SessionState.unauthenticated() : user = null;

  final AppUser? user;

  bool get isAuthenticated => user != null;

  @override
  List<Object?> get props => [user];
}

// Bloc -----------------------------------------------------------------------

/// Tracks the auth session for the whole app.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({required AuthRepository repository, required SignOut signOut})
    : _signOut = signOut,
      super(_stateFor(repository.currentUser)) {
    on<SessionUserChanged>((event, emit) => emit(_stateFor(event.user)));
    on<SessionSignOutRequested>(_onSignOutRequested);

    _subscription = repository.userChanges.listen(
      (user) => add(SessionUserChanged(user)),
    );
  }

  final SignOut _signOut;
  late final StreamSubscription<AppUser?> _subscription;

  static SessionState _stateFor(AppUser? user) => user == null
      ? const SessionState.unauthenticated()
      : SessionState.authenticated(user);

  Future<void> _onSignOutRequested(
    SessionSignOutRequested event,
    Emitter<SessionState> emit,
  ) async {
    await _signOut();
    // Leave the app even if the server call failed (e.g. offline): the local
    // session is cleared by the auth client either way.
    emit(const SessionState.unauthenticated());
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
