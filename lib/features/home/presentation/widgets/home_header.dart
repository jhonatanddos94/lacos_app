import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_greeting.dart';
import 'package:lacos_app/shared/widgets/avatars/profile_avatar.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.professionalName,
    required this.salonName,
    required this.onProfileTap,
    required this.onSalonTap,
    required this.now,
    this.professionalPhotoUrl,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
    super.key,
  });

  static const headerSkeletonKey = Key('home-header-skeleton');
  static const profileAvatarKey = Key('home-header-profile');
  static const salonButtonKey = Key('home-header-salon');
  static const retryButtonKey = Key('home-header-retry');

  /// Ícone da ação compacta "Meu salão" — mais leve que storefront.
  static const salonHeaderIcon = Icons.store_outlined;

  final String professionalName;
  final String? professionalPhotoUrl;
  final String salonName;
  final VoidCallback onProfileTap;
  final VoidCallback onSalonTap;
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
          _ProfileAvatarButton(
            key: profileAvatarKey,
            name: professionalName,
            photoUrl: professionalPhotoUrl,
            textStyle: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.purple800,
              fontWeight: FontWeight.w700,
            ),
            onTap: onProfileTap,
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
            key: salonButtonKey,
            icon: salonHeaderIcon,
            tooltip: AppStrings.mySalon,
            onPressed: onSalonTap,
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    required this.name,
    required this.onTap,
    this.photoUrl,
    this.textStyle,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.profile,
      child: Tooltip(
        message: AppStrings.profile,
        child: ExcludeSemantics(
          child: ProfileAvatar(
            name: name,
            photoUrl: photoUrl,
            radius: kMinInteractiveDimension / 2,
            onTap: onTap,
            initialTextStyle: textStyle,
          ),
        ),
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
          width: kMinInteractiveDimension,
          height: kMinInteractiveDimension,
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
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.purple50,
          borderRadius: AppRadius.borderSm,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadius.borderSm,
            child: SizedBox.square(
              dimension: kMinInteractiveDimension,
              child: Center(
                child: ExcludeSemantics(
                  child: Icon(
                    icon,
                    color: AppColors.purple700,
                    size: AppIconSizes.md,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
