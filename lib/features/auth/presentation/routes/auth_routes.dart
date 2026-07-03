import 'package:go_router/go_router.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/auth/presentation/pages/login_page.dart';

/// Rotas da feature Auth.
final List<RouteBase> authRoutes = [
  GoRoute(
    path: RoutePaths.login,
    builder: (context, state) => const LoginPage(),
  ),
];
