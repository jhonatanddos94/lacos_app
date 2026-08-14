import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/session/application/providers/session_providers.dart';
import 'package:lacos_app/core/session/domain/exceptions/auth_session_exception.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

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
  /// True while [signIn]/[createAccount] own the state machine.
  ///
  /// Firebase [AuthRepository.authenticatedUser] can emit as soon as
  /// `signInWithEmailAndPassword` succeeds, before Parse session sync.
  /// Those emissions must not replace [AuthLoading] or the login UI will
  /// treat the flow as finished (re-enable Entrar, navigate too early).
  var _isAuthOperationInProgress = false;

  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);

    final subscription = repository.authenticatedUser.listen(
      (user) {
        if (_isAuthOperationInProgress) return;
        state = switch (user) {
          null => const AuthUnauthenticated(),
          final user => AuthAuthenticated(user),
        };
      },
      onError: (error) {
        if (_isAuthOperationInProgress) return;
        state = AuthError(_resolveErrorMessage(error));
      },
    );

    ref.onDispose(subscription.cancel);

    final current = repository.currentUser;
    return switch (current) {
      null => const AuthUnauthenticated(),
      final user => AuthAuthenticated(user),
    };
  }

  Future<void> signIn({required String email, required String password}) async {
    await _runExclusiveAuthOperation(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);

      // Com exchange ON, Parse só após e-mail verificado (contrato Cloud Code).
      // Com legado, mantém sync imediato (comportamento existente).
      if (_shouldSyncParseAfterAuth(user)) {
        await ref.read(sessionRepositoryProvider).syncAuthenticatedUser();
      }

      state = AuthAuthenticated(user);
    });
  }

  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    await _runExclusiveAuthOperation(() async {
      final authRepository = ref.read(authRepositoryProvider);
      final sessionRepository = ref.read(sessionRepositoryProvider);

      final user = await authRepository.createAccount(
        email: email,
        password: password,
      );

      if (_shouldSyncParseAfterAuth(user)) {
        try {
          await sessionRepository.syncAuthenticatedUser();
        } on Object catch (error) {
          await _rollbackCreatedAccount(authRepository, error);
          throw const FormatException(
            'Não foi possível finalizar seu cadastro. Tente novamente.',
          );
        }
      }

      await authRepository.sendEmailVerification();
      state = AuthAuthenticated(user);
    });
  }

  Future<void> _runExclusiveAuthOperation(
    Future<void> Function() operation,
  ) async {
    _isAuthOperationInProgress = true;
    state = const AuthLoading();

    try {
      await operation();
    } on Object catch (error) {
      state = AuthError(_resolveErrorMessage(error));
    } finally {
      _isAuthOperationInProgress = false;
    }
  }

  /// Recarrega o usuário atual e atualiza o estado de autenticação.
  Future<void> reloadCurrentUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).reloadUser();
      if (user == null) {
        state = const AuthUnauthenticated();
        return;
      }
      state = AuthAuthenticated(user);
    } on Object catch (error) {
      state = AuthError(_resolveErrorMessage(error));
    }
  }

  /// Reenvia o e-mail de verificação e retorna se a operação teve sucesso.
  Future<bool> resendVerificationEmail() async {
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      return true;
    } on Object catch (error) {
      state = AuthError(_resolveErrorMessage(error));
      return false;
    }
  }

  /// Logout: Parse → Firebase.
  /// Se uma etapa falhar, tenta completar as demais.
  /// Workspace zera sozinho ao sair de [AuthAuthenticated].
  Future<bool> signOut() async {
    state = const AuthLoading();

    Object? firstError;

    try {
      await ref.read(sessionRepositoryProvider).signOut();
    } on Object catch (error) {
      firstError = error;
      _debugLog('Parse signOut failed: $error');
    }

    try {
      await ref.read(authRepositoryProvider).signOut();
    } on Object catch (error) {
      firstError ??= error;
      _debugLog('Firebase signOut failed: $error');
    }

    if (firstError != null) {
      state = AuthError(_resolveLogoutErrorMessage(firstError));
      return false;
    }

    return true;
  }

  bool _shouldSyncParseAfterAuth(AuthenticatedUser user) {
    final useExchange = ref.read(authFeatureFlagsProvider);
    if (!useExchange) {
      return true;
    }
    return user.isEmailVerified;
  }

  Future<void> _rollbackCreatedAccount(
    AuthRepository authRepository,
    Object syncError,
  ) async {
    _debugLog('Parse sync failed during account creation: $syncError');

    // Mantém Firebase e Parse consistentes quando o cadastro falha na etapa Parse.
    try {
      await authRepository.deleteCurrentUser();
      _debugLog('Firebase account rollback completed.');
    } on Object catch (error) {
      _debugLog('Firebase account rollback failed: $error');
    }

    try {
      await authRepository.signOut();
    } on Object catch (error) {
      _debugLog('Firebase sign out after rollback failed: $error');
    }
  }
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    AuthSessionException(:final message) => message,
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => 'Não foi possível entrar. Tente novamente.',
  };
}

String _resolveLogoutErrorMessage(Object error) {
  return switch (error) {
    AuthSessionException(:final message) => message,
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => AppStrings.logoutError,
  };
}

void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint('AuthController: $message');
  }
}
