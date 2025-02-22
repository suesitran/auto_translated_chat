import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

enum AuthenticationStatus {
  authenticated,
  unauthenticated,
}

class Authentication {
  final StreamController<AuthenticationStatus> _authStatusController =
      StreamController.broadcast();

  Stream<AuthenticationStatus> get authenticationStatus =>
      _authStatusController.stream;

  static Authentication? _instance;
  static Authentication get instance {
    _instance ??= Authentication._();
    return _instance!;
  }

  Authentication._() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _authStatusController.add(AuthenticationStatus.unauthenticated);
      } else {
        _authStatusController.add(AuthenticationStatus.authenticated);
      }
    });
  }

  String get uid {
    try {
      return FirebaseAuth.instance.currentUser!.uid;
    } catch (e) {
      // throw exception when get uid before user login
      rethrow;
    }
  }

  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;
}
