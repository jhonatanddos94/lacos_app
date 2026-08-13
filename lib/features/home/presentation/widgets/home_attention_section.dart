import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/application/services/home_today_summary_formatter.dart';

class HomeAttentionSection extends StatelessWidget {
  const HomeAttentionSection({
    required this.overdueCount,
    required this.onTap,
    super.key,
  });

  static const sectionKey = Key('home-attention');

  final int overdueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (overdueCount <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final message = HomeAttentionFormatter.format(overdueCount);

    return Semantics(
      button: true,
      label: AppStrings.homeOpenAttentionLabel,
      child: Material(
        key: sectionKey,
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderMd,
              boxShadow: AppShadows.level1,
              border: Border.all(color: const Color(0xFFFFE4C2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF4E5),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB8741A),
                    size: AppIconSizes.sm,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.homeAttentionTitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFB8741A),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
