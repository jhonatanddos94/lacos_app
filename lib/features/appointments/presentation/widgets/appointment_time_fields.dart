import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class AppointmentTimeFields extends StatelessWidget {
  const AppointmentTimeFields({
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.startTimeValue,
    required this.endTimeValue,
    this.onStartTap,
    this.onEndTap,
    this.startTimeHasError = false,
    super.key,
  });

  final String startTimeLabel;
  final String endTimeLabel;
  final String startTimeValue;
  final String endTimeValue;
  final VoidCallback? onStartTap;
  final VoidCallback? onEndTap;
  final bool startTimeHasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _TimeFieldTile(
            label: startTimeLabel,
            value: startTimeValue,
            hasError: startTimeHasError,
            onTap: onStartTap,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxs,
            AppSpacing.lg,
            AppSpacing.xxs,
            AppSpacing.xs,
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.65),
            size: AppIconSizes.sm,
          ),
        ),
        Expanded(
          child: _TimeFieldTile(
            label: endTimeLabel,
            value: endTimeValue,
            highlighted: true,
            onTap: onEndTap,
          ),
        ),
      ],
    );
  }
}

class _TimeFieldTile extends StatelessWidget {
  const _TimeFieldTile({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.hasError = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool highlighted;
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = hasError
        ? theme.colorScheme.error
        : highlighted
        ? AppColors.purple100
        : AppColors.divider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxs),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.borderMd,
            child: Ink(
              decoration: BoxDecoration(
                color: highlighted ? AppColors.purple50 : AppColors.surface,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: highlighted
                        ? AppColors.purple700
                        : AppColors.textSecondary,
                    size: AppIconSizes.sm,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    size: AppIconSizes.md,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
