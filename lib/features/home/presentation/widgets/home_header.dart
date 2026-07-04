import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_durations.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_greeting.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.professionalName,
    required this.salonName,
    super.key,
  });

  final String professionalName;
  final String salonName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = professionalName.split(' ').first;
    final initial = firstName.isEmpty ? 'L' : firstName.substring(0, 1);
    final greeting = HomeGreeting.resolve(
      DateTime.now(),
      professionalName: firstName,
    );

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
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.xxs),
          _HeaderIconButton(
            icon: Icons.account_circle_outlined,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

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
        tooltip: '',
      ),
    );
  }
}
