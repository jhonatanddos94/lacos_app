import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/auth/presentation/routes/auth_routes.dart';
import 'package:lacos_app/features/clients/presentation/routes/client_routes.dart';
import 'package:lacos_app/features/home/presentation/routes/home_routes.dart';
import 'package:lacos_app/features/memories/presentation/routes/memory_routes.dart';
import 'package:lacos_app/features/professional/presentation/routes/professional_routes.dart';
import 'package:lacos_app/features/salon/presentation/routes/salon_routes.dart';
import 'package:lacos_app/features/splash/presentation/routes/splash_routes.dart';

/// Provider do roteador principal da aplicação.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      ...splashRoutes,
      ...authRoutes(ref),
      ...salonRoutes(ref),
      ...professionalRoutes(ref),
      ...homeRoutes,
      ...clientRoutes,
      ...memoryRoutes,
    ],
  );
});
