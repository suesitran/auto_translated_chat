import 'package:get_it/get_it.dart';
import 'package:public_chat/repository/authentication.dart';
import 'package:public_chat/repository/database.dart';
import 'package:public_chat/repository/genai_model.dart';

class ServiceLocator {
  static ServiceLocator instance = ServiceLocator._();

  final GetIt _getIt = GetIt.asNewInstance();

  ServiceLocator._();

  void initialise() {
    registerSingletonIfNeeded(GenAiModel());
    registerSingletonIfNeeded(Database.instance);
    registerSingletonIfNeeded(Authentication.instance);
  }

  void registerSingletonIfNeeded<T extends Object>(T instance) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerSingleton<T>(instance);
    }
  }

  void reset() => _getIt.reset();

  T get<T extends Object>() {
    return _getIt.get<T>();
  }
}
