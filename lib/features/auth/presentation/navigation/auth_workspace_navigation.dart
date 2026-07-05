import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';

Future<void> navigateFromAuthenticatedWorkspace(
  WidgetRef ref,
  BuildContext context,
) async {
  ref.invalidate(workspaceProvider);

  final workspace = await ref.read(workspaceProvider.future);

  if (!context.mounted) return;

  context.go(AppRouteResolver.resolveFromWorkspace(workspace));
}
