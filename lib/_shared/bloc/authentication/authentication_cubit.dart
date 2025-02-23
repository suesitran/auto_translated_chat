import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:public_chat/repository/authentication.dart';
import 'package:public_chat/service_locator/service_locator.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final Authentication _authentication =
      ServiceLocator.instance.get<Authentication>();

  AuthenticationCubit() : super(AuthenticationInitial()) {
    _authentication.authenticationStatus.listen((status) {
      if (status == AuthenticationStatus.authenticated) {
        emit(Authenticated(_authentication.uid));
      } else {
        emit(Anonymous());
      }
    });

    if (_authentication.isAuthenticated) {
      emit(Authenticated(_authentication.uid));
    }
  }
}
