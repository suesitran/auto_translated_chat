import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:public_chat/_shared/bloc/authentication/authentication_cubit.dart';
import 'package:public_chat/repository/authentication.dart';
import 'package:public_chat/service_locator/service_locator.dart';

class MockAuthentication extends Mock implements Authentication {}

void main() {
  final MockAuthentication authentication = MockAuthentication();

  setUpAll(
    () {
      ServiceLocator.instance
          .registerSingletonIfNeeded<Authentication>(authentication);
    },
  );

  tearDown(
    () {
      reset(authentication);
    },
  );

  blocTest(
    'when stream does not update,'
    ' and user is not authenticated,'
    ' then do not change state',
    build: () => AuthenticationCubit(),
    setUp: () {
      when(
        () => authentication.authenticationStatus,
      ).thenAnswer(
        (invocation) => const Stream.empty(),
      );
      when(
        () => authentication.isAuthenticated,
      ).thenReturn(false);
    },
    expect: () => [],
    verify: (bloc) {
      expect(bloc.state, isA<AuthenticationInitial>());
    },
  );

  blocTest<AuthenticationCubit, AuthenticationState>(
    'when stream does not update,'
    ' and user is authenticated,'
    ' then change state to Authenticated',
    build: () => AuthenticationCubit(),
    setUp: () {
      when(
        () => authentication.authenticationStatus,
      ).thenAnswer(
        (invocation) => const Stream.empty(),
      );
      when(
        () => authentication.isAuthenticated,
      ).thenReturn(true);
      when(
        () => authentication.uid,
      ).thenReturn('uid');
    },
    expect: () => [],
    verify: (bloc) {
      expect(bloc.state, isA<Authenticated>());
    },
  );

  blocTest(
    'when stream change to authenticated,'
    ' then emit state Authenticated',
    build: () => AuthenticationCubit(),
    setUp: () {
      when(
        () => authentication.authenticationStatus,
      ).thenAnswer(
          (invocation) => Stream.value(AuthenticationStatus.authenticated));
      when(
        () => authentication.uid,
      ).thenAnswer(
        (invocation) => 'uid',
      );
      when(
        () => authentication.isAuthenticated,
      ).thenReturn(false);
    },
    expect: () => [isA<Authenticated>()],
  );

  blocTest(
    'when stream change to unauthenticated,'
    ' then emit Anonymous',
    build: () => AuthenticationCubit(),
    setUp: () {
      when(
        () => authentication.authenticationStatus,
      ).thenAnswer(
        (invocation) => Stream.value(AuthenticationStatus.unauthenticated),
      );
      when(
        () => authentication.isAuthenticated,
      ).thenReturn(false);
    },
    expect: () => [isA<Anonymous>()],
  );

  blocTest(
    'when authenticationStatus change,'
    ' then emit state accordingly',
    build: () => AuthenticationCubit(),
    setUp: () {
      when(
        () => authentication.authenticationStatus,
      ).thenAnswer((invocation) => Stream.fromIterable(
            [
              AuthenticationStatus.authenticated,
              AuthenticationStatus.unauthenticated
            ],
          ));
      when(
        () => authentication.uid,
      ).thenReturn('uid');
      when(
        () => authentication.isAuthenticated,
      ).thenReturn(false);
    },
    expect: () => [isA<Authenticated>(), isA<Anonymous>()],
  );
}
