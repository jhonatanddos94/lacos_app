import 'package:go_router/go_router.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/splash/presentation/pages/splash_page.dart';

/// Rotas da feature Splash.
final List<RouteBase> splashRoutes = [
  GoRoute(
    path: RoutePaths.splash,
    builder: (context, state) => const SplashPage(),
  ),
];
