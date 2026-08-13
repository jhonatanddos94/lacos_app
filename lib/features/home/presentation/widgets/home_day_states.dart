import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class HomeDayLoadingSkeleton extends StatelessWidget {
  const HomeDayLoadingSkeleton({super.key});

  static const skeletonKey = Key('home-day-skeleton');

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: skeletonKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardSkeleton(lines: 3),
        SizedBox(height: AppSpacing.md),
        _CardSkeleton(lines: 2),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.lines});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.level1,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBox(width: 72, height: 12),
          const SizedBox(height: AppSpacing.xs),
          const AppSkeletonBox(width: 160, height: 22),
          for (var i = 0; i < lines - 1; i++) ...[
            const SizedBox(height: AppSpacing.xxs),
            const AppSkeletonBox(width: double.infinity, height: 14),
          ],
        ],
      ),
    );
  }
}

class HomeDayErrorCard extends StatelessWidget {
  const HomeDayErrorCard({required this.onRetry, super.key});

  static const cardKey = Key('home-day-error');
  static const retryKey = Key('home-day-error-retry');

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: cardKey,
      width: double.infinity,
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.level1,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.homeDayLoadError,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.graphite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            key: retryKey,
            label: AppStrings.tryAgain,
            variant: AppButtonVariant.text,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
