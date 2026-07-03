/// Usuário autenticado no domínio do Laços.
class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.email,
  });

  final String id;
  final String email;
}
