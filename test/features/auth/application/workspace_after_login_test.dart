import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/session/application/providers/session_providers.dart';
import 'package:lacos_app/core/session/domain/repositories/session_repository.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

class _AuthRepository implements AuthRepository {
  AuthenticatedUser? user;

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
    user = const AuthenticatedUser(
      id: 'uid-1',
      email: 'a@test.com',
      isEmailVerified: true,
    );
    return user!;
  }

  @override
  Future<void> signOut() async {
    user = null;
  }
}

class _SessionRepository implements SessionRepository {
  @override
  Future<void> syncAuthenticatedUser({bool forceRefreshIdToken = false}) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  test(
    'workspace discards splash null after AuthController completes signIn',
    () async {
      final auth = _AuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sessionRepositoryProvider.overrideWithValue(_SessionRepository()),
          authFeatureFlagsProvider.overrideWithValue(false),
          workspaceProvider.overrideWith((ref) async {
            final user = ref.watch(currentAuthenticatedUserProvider);
            if (user == null) return null;
            return Workspace(user: user, salon: null, professional: null);
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(workspaceProvider.future), isNull);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@test.com', password: 'secret1');

      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());

      final workspace = await container.read(workspaceProvider.future);
      expect(workspace, isNotNull);
      expect(workspace!.user.id, 'uid-1');
    },
  );
}
