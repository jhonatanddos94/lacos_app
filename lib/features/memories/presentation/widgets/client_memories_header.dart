import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class ClientMemoriesHeader extends StatelessWidget {
  const ClientMemoriesHeader({
    required this.onBack,
    required this.onFilterTap,
    this.showFilterIndicator = false,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onFilterTap;
  final bool showFilterIndicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.xs,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            MemoryHeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    AppStrings.clientMemories,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    AppStrings.clientMemoriesSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
            MemoryHeaderIconButton(
              icon: Icons.tune_rounded,
              onPressed: onFilterTap,
              showIndicator: showFilterIndicator,
            ),
          ],
        ),
      ),
    );
  }
}

class MemoryHeaderIconButton extends StatelessWidget {
  const MemoryHeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.showIndicator = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool showIndicator;

  static const _indicatorSize = 8.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.onPrimary.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            color: AppColors.onPrimary,
            iconSize: AppIconSizes.md,
            tooltip: '',
          ),
        ),
        if (showIndicator)
          Positioned(
            top: AppSpacing.xxxs,
            right: AppSpacing.xxxs,
            child: Container(
              width: _indicatorSize,
              height: _indicatorSize,
              decoration: const BoxDecoration(
                color: AppColors.warmAmber,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
