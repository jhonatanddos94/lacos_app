import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/more/presentation/widgets/more_menu_tile.dart';

class MorePremiumCard extends StatelessWidget {
  const MorePremiumCard({
    required this.pricePerPeriod,
    required this.onTap,
    super.key,
  });

  static const cardKey = Key('more-premium-card');
  static const icon = Icons.auto_awesome_outlined;

  final String pricePerPeriod;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      key: cardKey,
      button: true,
      label: AppStrings.premiumCardSemantics(pricePerPeriod),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.purple50,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.purple100),
          boxShadow: AppShadows.level1,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.borderMd,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: SizedBox(
                        width: MoreMenuTile.iconContainerSize,
                        height: MoreMenuTile.iconContainerSize,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.purple100,
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.lacosPurple,
                            size: AppIconSizes.sm,
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
                            AppStrings.premiumTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.purple800,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxs),
                          Text(
                            AppStrings.premiumCardSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxs),
                          Text(
                            pricePerPeriod,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.purple700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxs),
                          Text(
                            AppStrings.premiumCardCta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.lacosPurple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.purple700,
                        size: AppIconSizes.md,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
