import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ClientMemoriesErrorState extends StatelessWidget {
  const ClientMemoriesErrorState({
    required this.onRetry,
    super.key,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.clientMemoriesLoadError,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.graphite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: AppStrings.tryAgain,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
