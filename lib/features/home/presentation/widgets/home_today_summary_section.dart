import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/application/services/home_today_summary_formatter.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class HomeTodaySummarySection extends StatelessWidget {
  const HomeTodaySummarySection({
    required this.presentation,
    required this.onOpenAgenda,
    required this.onNewAppointment,
    super.key,
  });

  static const sectionKey = Key('home-today-summary');
  static const newAppointmentCtaKey = Key('home-today-summary-new-appointment');

  final HomeTodaySummaryPresentation presentation;
  final VoidCallback onOpenAgenda;
  final VoidCallback onNewAppointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operationalLine = presentation.operationalLine;
    final secondaryLine = presentation.secondaryLine;
    final isEmpty = presentation.isEmpty;

    final card = Material(
      key: sectionKey,
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: isEmpty ? null : onOpenAgenda,
        borderRadius: AppRadius.borderMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            boxShadow: AppShadows.level1,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.homeTodayTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.purple700,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                presentation.totalLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (operationalLine != null) ...[
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  operationalLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (secondaryLine != null) ...[
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  secondaryLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              if (presentation.showNewAppointmentCta) ...[
                const SizedBox(height: AppSpacing.xxs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    key: newAppointmentCtaKey,
                    label: AppStrings.homeNewAppointmentCta,
                    variant: AppButtonVariant.text,
                    onPressed: onNewAppointment,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isEmpty) {
      return card;
    }

    return Semantics(
      button: true,
      label: AppStrings.homeOpenTodayAgendaLabel,
      child: card,
    );
  }
}
