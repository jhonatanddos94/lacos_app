import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';

/// Snapshot mínimo do usuário Parse em runtime (sem secrets).
class ParseUserSnapshot {
  const ParseUserSnapshot({
    required this.objectId,
    required this.username,
    this.sessionTokenPresent = false,
    this.firebaseUid,
  });

  final String objectId;
  final String username;
  final bool sessionTokenPresent;
  final String? firebaseUid;

  bool matchesFirebaseUid(String firebaseUid) {
    if (this.firebaseUid != null && this.firebaseUid == firebaseUid) {
      return true;
    }
    return username == firebaseUid;
  }
}

/// Porta de acesso ao Parse User — isolada para testes sem SDK real.
abstract interface class ParseUserSessionGateway {
  Future<ParseUserSnapshot?> currentUser();

  Future<void> login({
    required String username,
    required String password,
  });

  Future<void> signUp({
    required String username,
    required String password,
    required String email,
  });

  /// Equivalente a `Parse.User.become` no SDK Flutter:
  /// `ParseUser.getCurrentUserFromServer(sessionToken)`.
  Future<ParseUserSnapshot> becomeWithSessionToken(String sessionToken);

  Future<void> logout();

  Future<bool> userExistsByUsername(String username);

  /// Limpa estado local parcial sem depender de sucesso remoto.
  Future<void> clearLocalSession();
}

/// Contexto passado às estratégias de sessão.
class AuthSessionSyncContext {
  const AuthSessionSyncContext({
    required this.firebaseUser,
    this.forceRefreshIdToken = false,
  });

  final AuthenticatedUser firebaseUser;
  final bool forceRefreshIdToken;
}
