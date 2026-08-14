import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class MoreMenuTile extends StatelessWidget {
  const MoreMenuTile({
    required this.title,
    required this.onTap,
    required this.icon,
    this.iconColor = AppColors.purple700,
    this.iconBackgroundColor = AppColors.purple50,
    this.subtitle,
    this.showChevron = true,
    super.key,
  });

  static const minHeight = 48.0;
  static const iconContainerSize = 36.0;

  static const salonIcon = Icons.storefront_outlined;
  static const profileIcon = Icons.person_outline_rounded;
  static const helpIcon = Icons.help_outline_rounded;
  static const aboutIcon = Icons.info_outline_rounded;
  static const privacyIcon = Icons.privacy_tip_outlined;

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    final semanticsLabel = subtitle == null ? title : '$title. $subtitle';

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconBackgroundColor,
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: AppIconSizes.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxxs),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: AppIconSizes.md,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
