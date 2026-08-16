import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/monetization/application/monetization_providers.dart';
import 'package:lacos_app/features/more/presentation/navigation/more_navigation.dart';
import 'package:lacos_app/features/more/presentation/widgets/more_menu_tile.dart';
import 'package:lacos_app/features/more/presentation/widgets/more_premium_card.dart';
import 'package:lacos_app/features/professional/presentation/navigation/professional_profile_navigation.dart';
import 'package:lacos_app/features/salon/presentation/navigation/salon_navigation.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  static const pageKey = Key('more-page');
  static const salonItemKey = Key('more-item-salon');
  static const profileItemKey = Key('more-item-profile');
  static const helpItemKey = Key('more-item-help');
  static const aboutItemKey = Key('more-item-about');
  static const privacyItemKey = Key('more-item-privacy');
  static const businessGroupKey = Key('more-group-business');
  static const accountGroupKey = Key('more-group-account');
  static const supportGroupKey = Key('more-group-support');
  static const privacyGroupKey = Key('more-group-privacy');
  static const supportDividerKey = Key('more-support-divider');
  static const premiumCardKey = MorePremiumCard.cardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final privacyRequired = ref
        .watch(adsConsentControllerProvider)
        .privacyOptionsRequired;

    return SafeArea(
      bottom: false,
      child: ListView(
        key: pageKey,
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        children: [
          Text(
            AppStrings.moreTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.graphite,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxs),
          Text(
            AppStrings.moreSubtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          MorePremiumCard(
            pricePerPeriod: ref
                .watch(premiumProductConfigProvider)
                .pricePerPeriod,
            onTap: () => openPremiumPage(context),
          ),
          const SizedBox(height: AppSpacing.md),
          _MoreSection(
            title: AppStrings.moreBusinessSection,
            groupKey: businessGroupKey,
            children: [
              MoreMenuTile(
                key: salonItemKey,
                title: AppStrings.mySalon,
                subtitle: AppStrings.moreSalonSubtitle,
                icon: MoreMenuTile.salonIcon,
                iconColor: AppColors.lacosPurple,
                onTap: () => openSalonPage(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MoreSection(
            title: AppStrings.moreAccountSection,
            groupKey: accountGroupKey,
            children: [
              MoreMenuTile(
                key: profileItemKey,
                title: AppStrings.profile,
                subtitle: AppStrings.moreProfileSubtitle,
                icon: MoreMenuTile.profileIcon,
                iconBackgroundColor: AppColors.softLilac,
                onTap: () => openProfessionalProfile(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MoreSection(
            title: AppStrings.moreSupportSection,
            groupKey: supportGroupKey,
            children: [
              MoreMenuTile(
                key: helpItemKey,
                title: AppStrings.moreHelpSupport,
                icon: MoreMenuTile.helpIcon,
                iconColor: AppColors.softGreen,
                onTap: () => openHelpSupport(context),
              ),
              const Divider(
                key: supportDividerKey,
                height: 1,
                thickness: 1,
                color: AppColors.divider,
                indent:
                    AppSpacing.sm +
                    MoreMenuTile.iconContainerSize +
                    AppSpacing.xs,
                endIndent: AppSpacing.sm,
              ),
              MoreMenuTile(
                key: aboutItemKey,
                title: AppStrings.moreAbout,
                icon: MoreMenuTile.aboutIcon,
                iconColor: AppColors.softBlue,
                onTap: () => openAboutLacos(context),
              ),
            ],
          ),
          if (privacyRequired) ...[
            const SizedBox(height: AppSpacing.md),
            _MoreSection(
              title: AppStrings.morePrivacySection,
              groupKey: privacyGroupKey,
              children: [
                MoreMenuTile(
                  key: privacyItemKey,
                  title: AppStrings.adsPrivacyOptions,
                  subtitle: AppStrings.morePrivacySubtitle,
                  icon: MoreMenuTile.privacyIcon,
                  showChevron: false,
                  onTap: () {
                    ref
                        .read(adsConsentControllerProvider.notifier)
                        .showPrivacyOptions();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({
    required this.title,
    required this.groupKey,
    required this.children,
  });

  final String title;
  final Key groupKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.purple700,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.level1,
          ),
          child: Material(
            key: groupKey,
            color: Colors.transparent,
            borderRadius: AppRadius.borderMd,
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}
