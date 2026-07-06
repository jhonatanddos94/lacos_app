import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_select_tile.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_summary_card.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_time_fields.dart';

class AppointmentDateTimeSection extends StatelessWidget {
  const AppointmentDateTimeSection({
    required this.dateLabel,
    required this.dateError,
    required this.startTimeValue,
    required this.endTimeValue,
    required this.startTimeError,
    required this.durationSummaryLabel,
    required this.appointmentSummaryLabel,
    required this.onDateTap,
    required this.onStartTimeTap,
    required this.onEndTimeTap,
    super.key,
  });

  final String? dateLabel;
  final String? dateError;
  final String startTimeValue;
  final String endTimeValue;
  final String? startTimeError;
  final String durationSummaryLabel;
  final String? appointmentSummaryLabel;
  final VoidCallback onDateTap;
  final VoidCallback onStartTimeTap;
  final VoidCallback onEndTimeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppointmentFormSection(
      icon: Icons.calendar_month_outlined,
      title: AppStrings.appointmentDateTimeSection,
      subtitle: AppStrings.appointmentDateTimeSectionSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.appointmentDateLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxs),
          AppointmentFormSelectTile(
            title: dateLabel ?? AppStrings.appointmentChooseDatePrompt,
            subtitle: dateLabel == null
                ? AppStrings.appointmentChooseDateHint
                : null,
            leading: const AppointmentFormIconCircle(
              icon: Icons.calendar_today_outlined,
            ),
            hasError: dateError != null,
            onTap: onDateTap,
          ),
          if (dateError != null) ...[
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              dateError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppointmentTimeFields(
            startTimeLabel: AppStrings.appointmentStartTimeLabel,
            endTimeLabel: AppStrings.appointmentEndTimeLabel,
            startTimeValue: startTimeValue,
            endTimeValue: endTimeValue,
            startTimeHasError: startTimeError != null,
            onStartTap: onStartTimeTap,
            onEndTap: onEndTimeTap,
          ),
          if (startTimeError != null) ...[
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              startTimeError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppointmentSummaryCard(
            durationLabel: durationSummaryLabel,
            summaryLabel: appointmentSummaryLabel,
          ),
        ],
      ),
    );
  }
}
