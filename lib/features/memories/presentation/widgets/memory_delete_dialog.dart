import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class MemoryDeleteDialog extends ConsumerStatefulWidget {
  const MemoryDeleteDialog({required this.memory, super.key});

  final ClientMemory memory;

  @override
  ConsumerState<MemoryDeleteDialog> createState() => _MemoryDeleteDialogState();
}

class _MemoryDeleteDialogState extends ConsumerState<MemoryDeleteDialog> {
  Future<void> _confirmDelete() async {
    final success = await ref
        .read(memoryFormControllerProvider.notifier)
        .delete(widget.memory);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final error = ref.read(memoryFormControllerProvider).error;
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
      _ => AppStrings.memoryDeleteError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(memoryFormControllerProvider).isLoading;

    return AlertDialog(
      title: const Text(AppStrings.deleteMemoryTitle),
      content: Text(
        AppStrings.deleteMemoryMessage,
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
              : const Text(AppStrings.deleteMemory),
        ),
      ],
    );
  }
}
