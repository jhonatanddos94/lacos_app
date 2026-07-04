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

  Future<void> deleteCurrentUser();

  Future<void> signOut();
}
