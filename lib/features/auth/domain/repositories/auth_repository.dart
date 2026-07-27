import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';

abstract interface class AuthRepository {
  Stream<AuthenticatedUser?> get authenticatedUser;

  AuthenticatedUser? get currentUser;

  Future<AuthenticatedUser> signIn({
    required String email,
    required String password,
  });

  Future<AuthenticatedUser> createAccount({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<AuthenticatedUser?> reloadUser();

  /// Obtém o Firebase ID Token do usuário atual.
  ///
  /// [forceRefresh] `false` (padrão): usa cache do SDK quando válido.
  /// [forceRefresh] `true`: força emissão de novo token (restore / retry
  /// após `UNAUTHORIZED`).
  ///
  /// O token NÃO deve ser persistido pelo app — apenas usado em memória
  /// para a chamada imediata a `exchangeSession`.
  Future<String> getIdToken({bool forceRefresh = false});

  Future<void> deleteCurrentUser();

  Future<void> signOut();
}
