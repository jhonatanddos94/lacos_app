import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class MemoryArchiveDialog extends ConsumerStatefulWidget {
  const MemoryArchiveDialog({required this.memory, super.key});

  final ClientMemory memory;

  @override
  ConsumerState<MemoryArchiveDialog> createState() =>
      _MemoryArchiveDialogState();
}

class _MemoryArchiveDialogState extends ConsumerState<MemoryArchiveDialog> {
  Future<void> _confirmArchive() async {
    final memoryId = widget.memory.id;
    if (memoryId == null || memoryId.isEmpty) {
      _showMessage(AppStrings.memoryArchiveError);
      return;
    }

    final archived = await ref
        .read(clientMemoryActionsControllerProvider.notifier)
        .archive(memoryId);

    if (!mounted) return;

    if (archived != null) {
      Navigator.of(context).pop(true);
      return;
    }

    final errorMessage = ref
        .read(clientMemoryActionsControllerProvider)
        .errorMessage;
    if (errorMessage != null) {
      _showMessage(errorMessage);
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
    final isLoading = ref
        .watch(clientMemoryActionsControllerProvider)
        .isLoading;

    return AlertDialog(
      title: const Text(AppStrings.memoryArchiveTitle),
      content: Text(
        AppStrings.memoryArchiveMessage,
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
          onPressed: isLoading ? null : _confirmArchive,
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text(AppStrings.memoryArchiveAction),
        ),
      ],
    );
  }
}
