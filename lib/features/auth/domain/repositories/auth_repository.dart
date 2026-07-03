import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';

/// Contrato de autenticação do Laços.
abstract interface class AuthRepository {
  /// Emite o usuário autenticado atual e mudanças de sessão.
  /// `null` indica que não há sessão ativa.
  Stream<AuthenticatedUser?> get authenticatedUser;

  Future<AuthenticatedUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
