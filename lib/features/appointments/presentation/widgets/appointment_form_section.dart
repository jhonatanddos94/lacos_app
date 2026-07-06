import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class AppointmentFormSection extends StatelessWidget {
  const AppointmentFormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionLabel,
    this.onActionTap,
    this.errorText,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSpacing.lg,
              height: AppSpacing.lg,
              decoration: const BoxDecoration(
                color: AppColors.purple50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.purple700,
                size: AppIconSizes.sm,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xxxs),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              height: 1.35,
            ),
          ),
        ],
        if (actionLabel != null && onActionTap != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.lacosPurple,
              ),
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.lacosPurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
