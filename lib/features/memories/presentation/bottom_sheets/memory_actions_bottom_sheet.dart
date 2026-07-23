import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

enum MemoryAction { edit, pin, unpin, archive }

class MemoryActionsBottomSheet extends StatelessWidget {
  const MemoryActionsBottomSheet({required this.isPinned, super.key});

  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderTopLg,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.memoryActions,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  AppStrings.memoryActionsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MemoryActionTile(
                  icon: Icons.edit_outlined,
                  label: AppStrings.editMemory,
                  onTap: () => Navigator.of(context).pop(MemoryAction.edit),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                _MemoryActionTile(
                  icon: isPinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  label: isPinned
                      ? AppStrings.memoryUnpinAction
                      : AppStrings.memoryPinAction,
                  onTap: () => Navigator.of(context).pop(
                    isPinned ? MemoryAction.unpin : MemoryAction.pin,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                _MemoryActionTile(
                  icon: Icons.inventory_2_outlined,
                  label: AppStrings.memoryArchiveAction,
                  onTap: () => Navigator.of(context).pop(MemoryAction.archive),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppStrings.cancel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryActionTile extends StatelessWidget {
  const _MemoryActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.purple50.withValues(alpha: 0.45),
      borderRadius: AppRadius.borderMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.purple700, size: AppSpacing.sm),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
