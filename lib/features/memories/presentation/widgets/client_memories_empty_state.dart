import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ClientMemoriesEmptyState extends StatelessWidget {
  const ClientMemoriesEmptyState({required this.onAddMemory, super.key});

  final VoidCallback onAddMemory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.lacosLogo,
            width: AppSpacing.xxl,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Laços',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.clientMemoriesEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.purple800,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            AppStrings.clientMemoriesEmptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: AppStrings.addMemory, onPressed: onAddMemory),
        ],
      ),
    );
  }
}
