import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_date_formatters.dart';
import 'package:lacos_app/features/working_hours/application/models/working_hours_day_draft.dart';
import 'package:lacos_app/features/working_hours/presentation/helpers/working_hours_time_picker.dart';

class WorkingHoursDayRow extends StatelessWidget {
  const WorkingHoursDayRow({
    required this.day,
    required this.onWorkingChanged,
    required this.onStartTap,
    required this.onEndTap,
    super.key,
  });

  static Key weekdayKey(int weekday) => Key('working-hours-day-$weekday');

  final WorkingHoursDayDraft day;
  final ValueChanged<bool> onWorkingChanged;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekdayLabel = formatAgendaShortWeekday(day.weekday).toUpperCase();

    return Padding(
      key: weekdayKey(day.weekday),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  weekdayLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                day.isWorking
                    ? AppStrings.workingHoursWorkingLabel
                    : AppStrings.workingHoursNotWorkingLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: day.isWorking
                      ? AppColors.purple700
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xxxs),
              Switch.adaptive(
                key: Key('working-hours-switch-${day.weekday}'),
                value: day.isWorking,
                onChanged: onWorkingChanged,
              ),
            ],
          ),
          if (day.isWorking) ...[
            const SizedBox(height: AppSpacing.xxxs),
            Row(
              children: [
                Expanded(
                  child: _TimeChip(
                    key: Key('working-hours-start-${day.weekday}'),
                    label: AppStrings.workingHoursStartLabel,
                    value: formatWorkingHoursMinutes(day.startMinutes),
                    onTap: onStartTap,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                Expanded(
                  child: _TimeChip(
                    key: Key('working-hours-end-${day.weekday}'),
                    label: AppStrings.workingHoursEndLabel,
                    value: formatWorkingHoursMinutes(day.endMinutes),
                    onTap: onEndTap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.purple50,
      borderRadius: AppRadius.borderXs,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderXs,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.purple700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
