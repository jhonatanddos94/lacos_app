import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

enum AppointmentSelectedServiceAction { replace, remove }

class AppointmentSelectedServiceActionsBottomSheet extends StatelessWidget {
  const AppointmentSelectedServiceActionsBottomSheet({
    required this.service,
    super.key,
  });

  final Service service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = formatServiceDetails(
      durationMinutes: service.durationMinutes,
      price: service.price,
    );

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
                  service.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _SelectedServiceActionTile(
                  icon: Icons.swap_horiz_rounded,
                  label: AppStrings.appointmentReplaceService,
                  onTap: () => Navigator.of(context)
                      .pop(AppointmentSelectedServiceAction.replace),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                _SelectedServiceActionTile(
                  icon: Icons.remove_circle_outline_rounded,
                  label: AppStrings.appointmentRemoveSelectedService,
                  iconColor: AppColors.softRose,
                  labelColor: AppColors.softRose,
                  onTap: () => Navigator.of(context)
                      .pop(AppointmentSelectedServiceAction.remove),
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

class _SelectedServiceActionTile extends StatelessWidget {
  const _SelectedServiceActionTile({
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
