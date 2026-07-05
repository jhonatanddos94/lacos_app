import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/client_details_page.dart';

final List<RouteBase> clientRoutes = [
  GoRoute(
    path: RoutePaths.clientDetails,
    builder: (context, state) {
      final client = state.extra as Client;
      return ClientDetailsPage(client: client);
    },
  ),
];
