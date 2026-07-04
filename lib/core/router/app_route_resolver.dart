import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';
import 'package:lacos_app/features/auth/domain/entities/authenticated_user.dart';

abstract final class AppRouteResolver {
  static String resolveAfterAuth(AuthenticatedUser user) {
    if (!user.isEmailVerified) {
      return RoutePaths.verifyEmail;
    }

    return RoutePaths.welcome;
  }

  static String resolveAfterEmailVerified() {
    return RoutePaths.welcome;
  }

  static String resolveAfterSalonCreated() {
    return RoutePaths.completeProfile;
  }

  static String resolveAfterProfessionalCreated() {
    return RoutePaths.home;
  }

  static String resolveFromWorkspace(Workspace? workspace) {
    if (workspace == null) {
      return RoutePaths.login;
    }

    if (!workspace.hasVerifiedEmail) {
      return RoutePaths.verifyEmail;
    }

    if (!workspace.hasSalon) {
      return RoutePaths.welcome;
    }

    if (!workspace.hasProfessional) {
      return RoutePaths.completeProfile;
    }

    return RoutePaths.home;
  }
}
