import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_date_formatters.dart';

class AgendaDayChip extends StatelessWidget {
  const AgendaDayChip({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    this.isPast = false,
    super.key,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekday = formatAgendaShortWeekday(day.weekday);
    final backgroundColor = isSelected
        ? (isPast ? AppColors.graphite : AppColors.lacosPurple)
        : AppColors.surface;
    final borderColor = isSelected
        ? (isPast ? AppColors.graphite : AppColors.lacosPurple)
        : (isPast ? AppColors.divider.withValues(alpha: 0.7) : AppColors.divider);
    final textColor = isSelected
        ? AppColors.onPrimary
        : (isPast ? AppColors.textSecondary : AppColors.graphite);
    final subtitleColor = isSelected
        ? AppColors.onPrimary.withValues(alpha: 0.88)
        : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          width: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: borderColor),
            boxShadow: isSelected ? AppShadows.level1 : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                '${day.day}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: AppSpacing.xxxs),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.onPrimary : AppColors.lacosPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
