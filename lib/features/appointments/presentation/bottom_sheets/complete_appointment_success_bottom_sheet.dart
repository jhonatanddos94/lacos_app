import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/models/complete_appointment_success_action.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_header.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class CompleteAppointmentSuccessBottomSheet extends StatelessWidget {
  const CompleteAppointmentSuccessBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.xs,
          bottom: AppSpacing.lg,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppointmentBottomSheetHandle(),
              const SizedBox(height: AppSpacing.md),
              Icon(
                Icons.check_circle_rounded,
                size: AppIconSizes.lg,
                color: AppColors.purple700,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.appointmentCompleteSuccessSheetTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                AppStrings.appointmentCompleteSuccessSheetMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider.withValues(alpha: 0.65),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.appointmentCompleteSuccessMemoryPrompt,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                AppStrings.appointmentCompleteSuccessMemoryHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: AppStrings.appointmentCompleteSuccessRegisterMemory,
                onPressed: () => Navigator.of(context).pop(
                  CompleteAppointmentSuccessAction.addMemory,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: AppStrings.appointmentCompleteSuccessNotNow,
                variant: AppButtonVariant.text,
                onPressed: () => Navigator.of(context).pop(
                  CompleteAppointmentSuccessAction.dismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
