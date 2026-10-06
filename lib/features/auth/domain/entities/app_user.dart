import 'package:equatable/equatable.dart';

/// The signed-in account, independent of the auth provider.
class AppUser extends Equatable {
  const AppUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
