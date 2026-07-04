import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';
import 'package:lacos_app/features/auth/presentation/pages/login_page.dart';
import 'package:lacos_app/features/auth/presentation/pages/register_page.dart';
import 'package:lacos_app/features/auth/presentation/pages/verify_email_page.dart';
import 'package:lacos_app/features/auth/presentation/pages/welcome_page.dart';

/// Rotas da feature Auth.
List<RouteBase> authRoutes(Ref ref) => [
  GoRoute(
    path: RoutePaths.login,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    path: RoutePaths.register,
    builder: (context, state) => const RegisterPage(),
  ),
  GoRoute(
    path: RoutePaths.verifyEmail,
    builder: (context, state) => const VerifyEmailPage(),
  ),
  GoRoute(
    path: RoutePaths.welcome,
    redirect: (context, state) => _verifiedEmailRedirect(ref),
    builder: (context, state) => const WelcomePage(),
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
