import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/shell/presentation/pages/app_shell_page.dart';

final List<RouteBase> homeRoutes = [
  GoRoute(
    path: RoutePaths.home,
    builder: (context, state) => const AppShellPage(),
  ),
];
