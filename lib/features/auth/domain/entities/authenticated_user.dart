/// Usuário autenticado no domínio do Laços.
class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
  });

  final String id;
  final String email;
  final bool isEmailVerified;
}
