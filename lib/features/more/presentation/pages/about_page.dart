import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/more/application/providers/app_package_info_provider.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  static const pageKey = Key('about-page');
  static const versionKey = Key('about-version');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(appPackageInfoProvider);
    final version = packageInfo.valueOrNull?.version;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.graphite,
        elevation: 0,
        title: Text(
          AppStrings.moreAbout,
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
            Text(
              AppStrings.moreAboutAppName,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (version != null && version.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${AppStrings.moreVersionPrefix} $version',
                key: versionKey,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.moreAboutDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.moreAboutLegalPending,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
