import 'dart:async';

import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';

class FakeUnauthenticatedAuthRepository implements AuthRepository {
  @override
  Stream<AuthenticatedUser?> get authenticatedUser => Stream.value(null);

  @override
  AuthenticatedUser? get currentUser => null;

  @override
  Future<AuthenticatedUser> createAccount({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<AuthenticatedUser?> reloadUser() async => null;

  @override
  Future<void> sendEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<AuthenticatedUser> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}
