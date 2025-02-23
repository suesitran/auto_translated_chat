part of 'authentication_cubit.dart';

sealed class AuthenticationState extends Equatable {
  const AuthenticationState();
}

final class AuthenticationInitial extends AuthenticationState {
  @override
  List<Object> get props => [];
}

final class Authenticated extends AuthenticationState {
  final String uid;

  const Authenticated(this.uid);
  @override
  List<Object?> get props => [uid];
}

final class Anonymous extends AuthenticationState {
  @override
  List<Object?> get props => [];
}
