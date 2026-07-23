import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/auth/application/controllers/auth_controller.dart';
import 'package:lacos_app/features/auth/application/providers/auth_providers.dart';

class LogoutConfirmDialog extends ConsumerStatefulWidget {
  const LogoutConfirmDialog({super.key});

  @override
  ConsumerState<LogoutConfirmDialog> createState() =>
      _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends ConsumerState<LogoutConfirmDialog> {
  Future<void> _confirmLogout() async {
    final success = await ref.read(authControllerProvider.notifier).signOut();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState is AuthError) {
      _showMessage(authState.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return AlertDialog(
      title: const Text(AppStrings.logoutTitle),
      content: Text(
        AppStrings.logoutMessage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: isLoading ? null : _confirmLogout,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.softRose,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.softRose.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.7),
          ),
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text(AppStrings.logoutAction),
        ),
      ],
    );
  }
}
