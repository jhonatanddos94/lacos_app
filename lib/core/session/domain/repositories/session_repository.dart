/// Contrato responsável por preparar a sessão de domínio do Laços.
abstract interface class SessionRepository {
  /// Sincroniza sessão Parse com o usuário Firebase atual.
  ///
  /// [forceRefreshIdToken] força refresh do Firebase ID Token — útil no
  /// restore/bootstrap. Login imediato após Firebase Auth deve usar `false`.
  Future<void> syncAuthenticatedUser({bool forceRefreshIdToken = false});

  Future<void> signOut();
}
