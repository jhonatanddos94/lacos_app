import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/salon/presentation/pages/create_salon_page.dart';

List<RouteBase> salonRoutes(Ref ref) => [
  GoRoute(
    path: RoutePaths.createSalon,
    redirect: (context, state) => _verifiedEmailRedirect(ref),
    builder: (context, state) => const CreateSalonPage(),
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
