import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_select_tile.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_quick_choice_chip.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_summary_card.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_time_fields.dart';

class AppointmentDateTimeSection extends StatelessWidget {
  const AppointmentDateTimeSection({
    required this.dateDisplayLabel,
    required this.hasSelectedDate,
    required this.isTodaySelected,
    required this.isTomorrowSelected,
    required this.dateError,
    required this.startTimeValue,
    required this.endTimeValue,
    required this.selectedStartTimeMinutes,
    required this.startTimeError,
    required this.durationSummaryLabel,
    required this.appointmentSummaryLabel,
    required this.canCalculateAvailableTimes,
    required this.isLoadingAvailableTimes,
    required this.availabilityError,
    required this.displayedStartTimeMinutes,
    required this.showNoAvailableTimesMessage,
    required this.onDateTap,
    required this.onTodayTap,
    required this.onTomorrowTap,
    required this.onSelectStartTime,
    required this.onCustomStartTimeTap,
    this.onRetryAvailability,
    super.key,
  });

  final String? dateDisplayLabel;
  final bool hasSelectedDate;
  final bool isTodaySelected;
  final bool isTomorrowSelected;
  final String? dateError;
  final String startTimeValue;
  final String endTimeValue;
  final int? selectedStartTimeMinutes;
  final String? startTimeError;
  final String durationSummaryLabel;
  final String? appointmentSummaryLabel;
  final bool canCalculateAvailableTimes;
  final bool isLoadingAvailableTimes;
  final String? availabilityError;
  final List<int> displayedStartTimeMinutes;
  final bool showNoAvailableTimesMessage;
  final VoidCallback onDateTap;
  final VoidCallback onTodayTap;
  final VoidCallback onTomorrowTap;
  final ValueChanged<int> onSelectStartTime;
  final VoidCallback onCustomStartTimeTap;
  final VoidCallback? onRetryAvailability;

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
            title: dateDisplayLabel ?? AppStrings.appointmentChooseDatePrompt,
            subtitle: hasSelectedDate
                ? AppStrings.appointmentChangeDateHint
                : AppStrings.appointmentChooseDateHint,
            leading: const AppointmentFormIconCircle(
              icon: Icons.calendar_today_outlined,
            ),
            hasError: dateError != null,
            onTap: onDateTap,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xxs,
            children: [
              AppointmentQuickChoiceChip(
                label: AppStrings.appointmentDateToday,
                selected: isTodaySelected,
                onTap: onTodayTap,
              ),
              AppointmentQuickChoiceChip(
                label: AppStrings.appointmentDateTomorrow,
                selected: isTomorrowSelected,
                onTap: onTomorrowTap,
              ),
            ],
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
          ),
          const SizedBox(height: AppSpacing.xs),
          if (!canCalculateAvailableTimes)
            Text(
              AppStrings.appointmentAvailabilityPrerequisites,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            )
          else if (isLoadingAvailableTimes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxs),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (availabilityError != null) ...[
            Text(
              availabilityError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            if (onRetryAvailability != null) ...[
              const SizedBox(height: AppSpacing.xxxs),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onRetryAvailability,
                  child: const Text(AppStrings.tryAgain),
                ),
              ),
            ],
          ] else ...[
            if (showNoAvailableTimesMessage) ...[
              Text(
                AppStrings.appointmentNoAvailableTimes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
            ],
            Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final minutes in displayedStartTimeMinutes)
                  AppointmentQuickChoiceChip(
                    label: _formatTime(minutes),
                    selected: selectedStartTimeMinutes == minutes,
                    onTap: () => onSelectStartTime(minutes),
                  ),
                AppointmentQuickChoiceChip(
                  label: AppStrings.appointmentTimeOther,
                  selected: _isCustomStartTimeSelected(),
                  onTap: onCustomStartTimeTap,
                ),
              ],
            ),
          ],
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

  bool _isCustomStartTimeSelected() {
    final selectedMinutes = selectedStartTimeMinutes;
    if (selectedMinutes == null) return false;

    return !displayedStartTimeMinutes.contains(selectedMinutes);
  }

  String _formatTime(int totalMinutes) {
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
