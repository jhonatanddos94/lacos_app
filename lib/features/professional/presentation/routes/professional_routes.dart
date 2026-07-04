import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/professional/presentation/pages/complete_profile_page.dart';

List<RouteBase> professionalRoutes(Ref ref) => [
  GoRoute(
    path: RoutePaths.completeProfile,
    redirect: (context, state) => _verifiedEmailRedirect(ref),
    builder: (context, state) => const CompleteProfilePage(),
  ),
];

String? _verifiedEmailRedirect(Ref ref) {
  return switch (ref.read(authControllerProvider)) {
    AuthAuthenticated(user: final user) when user.isEmailVerified => null,
    AuthAuthenticated(user: final user) => AppRouteResolver.resolveAfterAuth(
      user,
    ),
    AuthLoading() => null,
    _ => RoutePaths.login,
  };
}
