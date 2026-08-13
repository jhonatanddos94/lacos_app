import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/services/home_upcoming_days_formatter.dart';

class HomeUpcomingDaysSection extends StatelessWidget {
  const HomeUpcomingDaysSection({
    required this.days,
    required this.today,
    required this.onOpenAgenda,
    required this.onOpenDay,
    super.key,
  });

  static const sectionKey = Key('home-upcoming-days');
  static const openAgendaKey = Key('home-upcoming-days-open-agenda');

  static Key rowKey(DateTime day) =>
      Key('home-upcoming-day-${day.year}-${day.month}-${day.day}');

  final List<HomeUpcomingDay> days;
  final DateTime today;
  final VoidCallback onOpenAgenda;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxxs,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              AppStrings.homeUpcomingDaysTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.purple700,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              key: openAgendaKey,
              onPressed: onOpenAgenda,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text(
                AppStrings.homeUpcomingDaysOpenAgenda,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surface,
          borderRadius: AppRadius.borderMd,
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                for (var index = 0; index < days.length; index++) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                  _UpcomingDayRow(
                    key: rowKey(days[index].day),
                    dayLabel: HomeUpcomingDaysFormatter.formatDayLabel(
                      day: days[index].day,
                      today: today,
                    ),
                    countLabel: HomeUpcomingDaysFormatter.formatCountLabel(
                      days[index].appointmentCount,
                    ),
                    semanticsLabel: HomeUpcomingDaysFormatter.formatSemanticsLabel(
                      day: days[index].day,
                      today: today,
                      count: days[index].appointmentCount,
                    ),
                    onTap: () => onOpenDay(days[index].day),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingDayRow extends StatelessWidget {
  const _UpcomingDayRow({
    required this.dayLabel,
    required this.countLabel,
    required this.semanticsLabel,
    required this.onTap,
    super.key,
  });

  final String dayLabel;
  final String countLabel;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.graphite,
      fontWeight: FontWeight.w600,
    );
    final countStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    );

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(dayLabel, style: dayStyle),
                      Text(countLabel, style: countStyle),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: AppIconSizes.sm,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
