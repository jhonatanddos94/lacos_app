import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/monetization/application/monetization_providers.dart';
import 'package:lacos_app/features/monetization/domain/monetization_tier.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  static const pageKey = Key('premium-page');
  static const activeStatusKey = Key('premium-active-status');
  static const ctaKey = Key('premium-cta');
  static const priceKey = Key('premium-price');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final access = ref.watch(monetizationAccessProvider);
    final product = ref.watch(premiumProductConfigProvider);
    final isPremium = access.tier == MonetizationTier.premium;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.graphite,
        elevation: 0,
        title: Text(
          AppStrings.premiumTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: pageKey,
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.lg,
          ),
          children: [
            const _PremiumHero(),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.premiumPageHeadline,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              AppStrings.premiumPageSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (isPremium) ...[
              const SizedBox(height: AppSpacing.md),
              const _PremiumActiveStatus(),
            ],
            const SizedBox(height: AppSpacing.lg),
            const _PremiumBenefit(
              icon: Icons.visibility_off_outlined,
              title: AppStrings.premiumBenefitAdsTitle,
              body: AppStrings.premiumBenefitAdsBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _PremiumBenefit(
              icon: Icons.favorite_border_rounded,
              title: AppStrings.premiumBenefitEvolutionTitle,
              body: AppStrings.premiumBenefitEvolutionBody,
            ),
            if (!isPremium) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                product.displayPrice,
                key: priceKey,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.purple800,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                AppStrings.premiumPricePeriod,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                AppStrings.premiumBillingNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                button: true,
                enabled: false,
                label: AppStrings.premiumCtaPreparing,
                child: const AppButton(
                  key: ctaKey,
                  label: AppStrings.premiumCtaPreparing,
                  onPressed: null,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                AppStrings.premiumCtaPreparingHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ExcludeSemantics(
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.purple100,
          ),
          child: const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.lacosPurple,
            size: AppIconSizes.lg,
          ),
        ),
      ),
    );
  }
}

class _PremiumActiveStatus extends StatelessWidget {
  const _PremiumActiveStatus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${AppStrings.premiumActiveStatus}. ${AppStrings.premiumActiveBody}',
      child: DecoratedBox(
        key: PremiumPage.activeStatusKey,
        decoration: BoxDecoration(
          color: AppColors.purple50,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.purple100),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.purple700,
                  size: AppIconSizes.md,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.premiumActiveStatus,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.purple800,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(
                      AppStrings.premiumActiveBody,
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
        ),
      ),
    );
  }
}

class _PremiumBenefit extends StatelessWidget {
  const _PremiumBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.level1,
      ),
      child: Padding(
        padding: AppSpacing.paddingSm,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 36,
                height: 36,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple50,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.purple700,
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
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    body,
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
      ),
    );
  }
}
