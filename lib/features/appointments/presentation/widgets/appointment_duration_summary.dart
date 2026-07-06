import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class AppointmentDurationSummary extends StatelessWidget {
  const AppointmentDurationSummary({
    required this.durationLabel,
    this.summaryLabel,
    super.key,
  });

  final String durationLabel;
  final String? summaryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.purple100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.purple700,
            size: AppSpacing.sm,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✨ $durationLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.purple800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (summaryLabel != null) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    summaryLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.purple700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
