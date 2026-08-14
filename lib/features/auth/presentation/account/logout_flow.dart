import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/features/auth/presentation/widgets/logout_confirm_dialog.dart';

Future<void> confirmLogout(BuildContext context) async {
  final success = await showDialog<bool>(
    context: context,
    builder: (context) => const LogoutConfirmDialog(),
  );

  if (!context.mounted || success != true) return;

  final router = GoRouter.maybeOf(context);
  if (router == null) return;

  router.go(RoutePaths.login);
}
