import 'package:firebase_auth/firebase_auth.dart';

import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';

/// Converte usuários do Firebase Authentication para o domínio do Laços.
class FirebaseUserMapper {
  const FirebaseUserMapper();

  AuthenticatedUser? toDomain(User? user) {
    if (user == null) return null;

    final email = user.email;
    if (email == null || email.isEmpty) return null;

    return AuthenticatedUser(
      id: user.uid,
      email: email,
      isEmailVerified: user.emailVerified,
    );
  }
}
