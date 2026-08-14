import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/session/application/providers/session_providers.dart';
import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/core/session/domain/repositories/session_repository.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

class _StreamingAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthenticatedUser?>.broadcast();

  AuthenticatedUser? user;
  AuthenticatedUser Function() onSignIn = _verified;
  Object? signInError;
  int signInCalls = 0;

  void dispose() {
    _controller.close();
  }

  @override
  Stream<AuthenticatedUser?> get authenticatedUser => _controller.stream;

  @override
  AuthenticatedUser? get currentUser => user;

  @override
  Future<AuthenticatedUser> createAccount({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCurrentUser() async {}

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async => 'token';

  @override
  Future<AuthenticatedUser?> reloadUser() async => user;

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AuthenticatedUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (signInError != null) {
      throw signInError!;
    }

    user = onSignIn();
    // Firebase authStateChanges emits as soon as the credential future
    // completes, before Parse session sync in AuthController.
    _controller.add(user);
    return user!;
  }

  @override
  Future<void> signOut() async {
    user = null;
    _controller.add(null);
  }
}

class _GatedSessionRepository implements SessionRepository {
  final syncGate = Completer<void>();
  int syncCalls = 0;
  Object? syncError;

  @override
  Future<void> syncAuthenticatedUser({bool forceRefreshIdToken = false}) async {
    syncCalls++;
    await syncGate.future;
    if (syncError != null) {
      throw syncError!;
    }
  }

  @override
  Future<void> signOut() async {}
}

AuthenticatedUser _verified() => const AuthenticatedUser(
  id: 'uid-1',
  email: 'a@test.com',
  isEmailVerified: true,
);

void main() {
  late _StreamingAuthRepository auth;
  late _GatedSessionRepository session;
  late ProviderContainer container;

  setUp(() {
    auth = _StreamingAuthRepository();
    session = _GatedSessionRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        sessionRepositoryProvider.overrideWithValue(session),
        authFeatureFlagsProvider.overrideWithValue(false),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    auth.dispose();
  });

  test(
    'Firebase authStateChanges during signIn does not leave AuthLoading',
    () async {
      final signInFuture = container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@test.com', password: 'secret1');

      await Future<void>.value();
      await Future<void>.value();

      expect(auth.signInCalls, 1);
      expect(session.syncCalls, 1);
      expect(container.read(authControllerProvider), isA<AuthLoading>());

      session.syncGate.complete();
      await signInFuture;

      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    },
  );

  test('Parse failure after Firebase stays AuthError, not Home-ready', () async {
    session.syncError = const AuthSessionException(
      code: 'PARSE',
      message: 'Não foi possível sincronizar sua sessão.',
    );

    final signInFuture = container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@test.com', password: 'secret1');

    await Future<void>.value();
    session.syncGate.complete();
    await signInFuture;

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthError>());
    expect(
      (state as AuthError).message,
      'Não foi possível sincronizar sua sessão.',
    );
    expect(auth.currentUser, isNotNull);
  });
}
