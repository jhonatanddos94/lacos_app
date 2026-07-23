import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class AppointmentQuickChoiceChip extends StatelessWidget {
  const AppointmentQuickChoiceChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : selected
        ? AppColors.purple700
        : AppColors.graphite;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: selected ? AppColors.purple50 : AppColors.surface,
        borderRadius: AppRadius.borderSm,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.borderSm,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderSm,
              border: Border.all(
                color: selected && enabled
                    ? AppColors.purple700
                    : AppColors.divider,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxxs,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foregroundColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
