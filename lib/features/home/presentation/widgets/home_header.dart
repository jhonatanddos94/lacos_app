import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_greeting.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.professionalName,
    required this.salonName,
    required this.onAccountTap,
    required this.now,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
    super.key,
  });

  static const headerSkeletonKey = Key('home-header-skeleton');
  static const accountButtonKey = Key('home-header-account');
  static const retryButtonKey = Key('home-header-retry');

  final String professionalName;
  final String salonName;
  final VoidCallback onAccountTap;
  final DateTime now;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _HomeHeaderSkeleton();
    }

    final theme = Theme.of(context);
    final firstName = professionalName.split(' ').first;
    final initial = firstName.isEmpty ? 'L' : firstName.substring(0, 1);
    final greeting = HomeGreeting.resolve(now, professionalName: firstName);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.medium,
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple100,
            ),
            child: Center(
              child: Text(
                initial.toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.purple800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  salonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  TextButton(
                    key: retryButtonKey,
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(AppStrings.tryAgain),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _HeaderIconButton(
            key: accountButtonKey,
            icon: Icons.account_circle_outlined,
            tooltip: AppStrings.account,
            onPressed: onAccountTap,
          ),
        ],
      ),
    );
  }
}

class _HomeHeaderSkeleton extends StatelessWidget {
  const _HomeHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: HomeHeader.headerSkeletonKey,
      children: [
        AppSkeletonBox(
          width: 48,
          height: 48,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(width: 180, height: 18),
              SizedBox(height: AppSpacing.xxs),
              AppSkeletonBox(width: 120, height: 14),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        AppSkeletonBox(
          width: 40,
          height: 40,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderSm,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.purple700,
        iconSize: AppIconSizes.md,
        tooltip: tooltip,
        constraints: const BoxConstraints(
          minWidth: kMinInteractiveDimension,
          minHeight: kMinInteractiveDimension,
        ),
      ),
    );
  }
}
