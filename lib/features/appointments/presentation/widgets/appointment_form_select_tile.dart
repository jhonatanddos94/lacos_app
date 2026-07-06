import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class AppointmentFormSelectTile extends StatelessWidget {
  const AppointmentFormSelectTile({
    required this.title,
    this.subtitle,
    this.detail,
    this.leading,
    this.backgroundColor = AppColors.surface,
    this.hasError = false,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? detail;
  final Widget? leading;
  final Color backgroundColor;
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        hasError ? theme.colorScheme.error : AppColors.divider;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (detail != null) ...[
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                size: AppIconSizes.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppointmentFormIconCircle extends StatelessWidget {
  const AppointmentFormIconCircle({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.purple50,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: AppColors.purple700,
        size: AppIconSizes.sm,
      ),
    );
  }
}
