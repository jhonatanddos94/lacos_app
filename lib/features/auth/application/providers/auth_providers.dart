import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';
import 'package:lacos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lacos_app/features/auth/infrastructure/repositories/firebase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// User that [AuthController] has finished authenticating (Firebase + Parse).
///
/// [workspaceProvider] must watch this — not [AuthRepository.currentUser] —
/// so a splash-cached `null` is discarded when login completes.
final currentAuthenticatedUserProvider = Provider<AuthenticatedUser?>((ref) {
  return switch (ref.watch(authControllerProvider)) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };
});

