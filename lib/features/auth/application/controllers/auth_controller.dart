import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthenticatedUser user;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);

    final subscription = repository.authenticatedUser.listen(
      (user) {
        state = switch (user) {
          null => const AuthUnauthenticated(),
          final user => AuthAuthenticated(user),
        };
      },
      onError: (error) {
        state = AuthError(_resolveErrorMessage(error));
      },
    );

    ref.onDispose(subscription.cancel);

    return const AuthUnauthenticated();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
    } on Object catch (error) {
      state = AuthError(_resolveErrorMessage(error));
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();

    try {
      await ref.read(authRepositoryProvider).signOut();
    } on Object catch (error) {
      state = AuthError(_resolveErrorMessage(error));
    }
  }
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => 'Não foi possível entrar. Tente novamente.',
  };
}
