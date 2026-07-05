import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/memories/presentation/pages/client_memories_page.dart';

final List<RouteBase> memoryRoutes = [
  GoRoute(
    path: RoutePaths.clientMemories,
    builder: (context, state) {
      final client = state.extra as Client;
      return ClientMemoriesPage(client: client);
    },
  ),
];
