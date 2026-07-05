import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/auth/presentation/bottom_sheets/account_actions_bottom_sheet.dart';
import 'package:lacos_app/features/auth/presentation/widgets/logout_confirm_dialog.dart';

Future<void> showAccountActionsFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final action = await showModalBottomSheet<AccountAction>(
    context: context,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) => const AccountActionsBottomSheet(),
  );

  if (!context.mounted || action == null) return;

  if (action == AccountAction.logout) {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmDialog(),
    );

    if (!context.mounted || success != true) return;

    context.go(RoutePaths.login);
  }
}
