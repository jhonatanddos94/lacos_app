/// Contrato responsável por preparar a sessão de domínio do Laços.
abstract interface class SessionRepository {
  Future<void> syncAuthenticatedUser();
}
