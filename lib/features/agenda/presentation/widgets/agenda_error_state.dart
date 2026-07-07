import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

String resolveAgendaErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) when message.isNotEmpty => message,
    StateError(message: final message) => message,
    _ => AppStrings.temporaryLoadError,
  };
}

class AgendaErrorState extends StatelessWidget {
  const AgendaErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: AppRadius.borderMd,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.level1,
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
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
        ),
      ),
    );
  }
}
