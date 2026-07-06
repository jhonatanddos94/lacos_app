import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

enum ServiceAction { edit, delete }

class ServiceActionsBottomSheet extends StatelessWidget {
  const ServiceActionsBottomSheet({super.key});

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
                  AppStrings.serviceActions,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  AppStrings.serviceActionsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ServiceActionTile(
                  icon: Icons.edit_outlined,
                  label: AppStrings.editService,
                  onTap: () => Navigator.of(context).pop(ServiceAction.edit),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                _ServiceActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: AppStrings.deleteService,
                  iconColor: AppColors.softRose,
                  labelColor: AppColors.softRose,
                  onTap: () => Navigator.of(context).pop(ServiceAction.delete),
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

class _ServiceActionTile extends StatelessWidget {
  const _ServiceActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.purple700,
    this.labelColor = AppColors.graphite,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;

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
              Icon(icon, color: iconColor, size: AppSpacing.sm),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: labelColor,
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
