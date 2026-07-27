import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/session/application/providers/session_providers.dart';
import 'package:lacos_app/core/session/domain/repositories/session_repository.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

class _RecordingSessionRepository implements SessionRepository {
  int syncCalls = 0;
  int signOutCalls = 0;
  Object? signOutError;

  @override
  Future<void> syncAuthenticatedUser({bool forceRefreshIdToken = false}) async {
    syncCalls++;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError != null) {
      throw signOutError!;
    }
  }
}

class _SignInAuthRepository implements AuthRepository {
  _SignInAuthRepository({required this.onSignIn, this.user});

  final AuthenticatedUser Function() onSignIn;
  AuthenticatedUser? user;
  bool firebaseSignedOut = false;

  @override
  Stream<AuthenticatedUser?> get authenticatedUser => Stream.value(user);

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
    user = onSignIn();
    return user!;
  }

  @override
  Future<void> signOut() async {
    firebaseSignedOut = true;
    user = null;
  }
}

AuthenticatedUser _verified() => const AuthenticatedUser(
  id: 'uid-1',
  email: 'a@test.com',
  isEmailVerified: true,
);

AuthenticatedUser _unverified() => const AuthenticatedUser(
  id: 'uid-1',
  email: 'a@test.com',
  isEmailVerified: false,
);

void main() {
  group('AuthController dual-run', () {
    test('exchange flag ON skips Parse sync for unverified login', () async {
      final session = _RecordingSessionRepository();
      final auth = _SignInAuthRepository(onSignIn: _unverified);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sessionRepositoryProvider.overrideWithValue(session),
          authFeatureFlagsProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@test.com', password: 'x');

      expect(session.syncCalls, 0);
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    });

    test('exchange flag ON syncs Parse for verified login', () async {
      final session = _RecordingSessionRepository();
      final auth = _SignInAuthRepository(onSignIn: _verified);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sessionRepositoryProvider.overrideWithValue(session),
          authFeatureFlagsProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@test.com', password: 'x');

      expect(session.syncCalls, 1);
    });

    test('legacy flag OFF always syncs Parse after login', () async {
      final session = _RecordingSessionRepository();
      final auth = _SignInAuthRepository(onSignIn: _unverified);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sessionRepositoryProvider.overrideWithValue(session),
          authFeatureFlagsProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@test.com', password: 'x');

      expect(session.syncCalls, 1);
    });

    test('logout clears Parse then Firebase even if Parse fails', () async {
      final session = _RecordingSessionRepository()
        ..signOutError = const FormatException('parse fail');
      final auth = _SignInAuthRepository(
        onSignIn: _verified,
        user: _verified(),
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sessionRepositoryProvider.overrideWithValue(session),
          authFeatureFlagsProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container.read(authControllerProvider.notifier).signOut();

      expect(ok, isFalse);
      expect(session.signOutCalls, 1);
      expect(auth.firebaseSignedOut, isTrue);
      expect(container.read(authControllerProvider), isA<AuthError>());
    });
  });
}
