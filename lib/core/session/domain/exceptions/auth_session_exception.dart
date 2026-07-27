/// Exceção de sincronização de sessão com código estável (sem secrets).
class AuthSessionException implements Exception {
  const AuthSessionException({
    required this.code,
    required this.message,
  });

  /// Código sanitizado: VALIDATION, UNAUTHORIZED, EMAIL_UNVERIFIED, etc.
  final String code;

  /// Mensagem amigável para UI (padrão atual do app).
  final String message;

  @override
  String toString() => message;
}
