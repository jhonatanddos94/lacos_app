import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class ServiceDeleteDialog extends ConsumerStatefulWidget {
  const ServiceDeleteDialog({required this.service, super.key});

  final Service service;

  @override
  ConsumerState<ServiceDeleteDialog> createState() => _ServiceDeleteDialogState();
}

class _ServiceDeleteDialogState extends ConsumerState<ServiceDeleteDialog> {
  Future<void> _confirmDelete() async {
    final success = await ref
        .read(serviceFormControllerProvider.notifier)
        .delete(widget.service);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final error = ref.read(serviceFormControllerProvider).error;
    if (error != null) {
      _showMessage(_resolveErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _resolveErrorMessage(Object error) {
    return switch (error) {
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ => AppStrings.serviceDeleteError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(serviceFormControllerProvider).isLoading;

    return AlertDialog(
      title: const Text(AppStrings.deleteServiceTitle),
      content: Text(
        AppStrings.deleteServiceMessage,
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
          onPressed: isLoading ? null : _confirmDelete,
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
              : const Text(AppStrings.deleteService),
        ),
      ],
    );
  }
}
