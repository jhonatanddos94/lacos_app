import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_month_grid.dart';

Future<DateTime?> showAgendaCalendarBottomSheet({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) {
      return AgendaCalendarBottomSheet(
        initialDate: normalizeCalendarDay(initialDate),
      );
    },
  );
}

class AgendaCalendarBottomSheet extends StatefulWidget {
  const AgendaCalendarBottomSheet({
    required this.initialDate,
    this.daysWithAppointments = const {},
    this.onDisplayedMonthChanged,
    super.key,
  });

  final DateTime initialDate;
  final Set<DateTime> daysWithAppointments;
  final ValueChanged<AgendaCalendarMonthGrid>? onDisplayedMonthChanged;

  @override
  State<AgendaCalendarBottomSheet> createState() =>
      _AgendaCalendarBottomSheetState();
}

class _AgendaCalendarBottomSheetState extends State<AgendaCalendarBottomSheet> {
  late AgendaCalendarMonthGrid _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = AgendaCalendarMonthGrid.fromDate(widget.initialDate);
  }

  void _showPreviousMonth() {
    setState(() {
      _displayedMonth = _displayedMonth.previousMonth();
      widget.onDisplayedMonthChanged?.call(_displayedMonth);
    });
  }

  void _showNextMonth() {
    setState(() {
      _displayedMonth = _displayedMonth.nextMonth();
      widget.onDisplayedMonthChanged?.call(_displayedMonth);
    });
  }

  void _selectDay(DateTime day) {
    Navigator.of(context).pop(normalizeCalendarDay(day));
  }

  void _selectToday() {
    Navigator.of(context).pop(normalizeCalendarDay(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = normalizeCalendarDay(DateTime.now());
    final cells = _displayedMonth.buildCells();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: AppSpacing.screenPadding.copyWith(
              top: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _CalendarBottomSheetHandle(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _displayedMonth.titleLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _MonthNavButton(
                      label: _displayedMonth.previousMonthLabel,
                      icon: Icons.chevron_left_rounded,
                      onPressed: _showPreviousMonth,
                    ),
                    const Spacer(),
                    _MonthNavButton(
                      label: _displayedMonth.nextMonthLabel,
                      icon: Icons.chevron_right_rounded,
                      iconAfterLabel: true,
                      onPressed: _showNextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final label in AgendaCalendarMonthGrid.weekdayLabels)
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cells.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: 48,
                  ),
                  itemBuilder: (context, index) {
                    final cell = cells[index];
                    final normalizedDate = normalizeCalendarDay(cell.date);
                    final isSelected = isSameCalendarDay(
                      normalizedDate,
                      widget.initialDate,
                    );
                    final isToday = isSameCalendarDay(normalizedDate, today);
                    final hasAppointments = calendarDayHasAppointments(
                      normalizedDate,
                      widget.daysWithAppointments,
                    );

                    return _CalendarDayButton(
                      date: normalizedDate,
                      isCurrentMonth: cell.isCurrentMonth,
                      isSelected: isSelected,
                      isToday: isToday,
                      hasAppointments: hasAppointments,
                      onTap: () => _selectDay(normalizedDate),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider.withValues(alpha: 0.85),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  key: const Key('agenda-calendar-today'),
                  onPressed: _selectToday,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: AppColors.purple700,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text(AppStrings.appointmentDateToday),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarBottomSheetHandle extends StatelessWidget {
  const _CalendarBottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: AppRadius.borderLg,
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconAfterLabel = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool iconAfterLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: AppColors.purple700,
        fontWeight: FontWeight.w600,
      ),
    );
    final iconWidget = Icon(icon, color: AppColors.purple700, size: 20);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xxxs,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: iconAfterLabel
            ? [text, iconWidget]
            : [iconWidget, text],
      ),
    );
  }
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasAppointments,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasAppointments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = date.day;
    final foregroundColor = !isCurrentMonth
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : isSelected
        ? AppColors.onPrimary
        : AppColors.graphite;
    final indicatorColor = isSelected
        ? AppColors.onPrimary.withValues(alpha: 0.92)
        : isCurrentMonth
        ? AppColors.lacosPurple
        : AppColors.textSecondary.withValues(alpha: 0.55);

    return Semantics(
      button: true,
      selected: isSelected,
      label: hasAppointments ? '$day, com atendimentos' : '$day',
      child: Material(
        key: Key(
          'agenda-calendar-day-${date.year}-${date.month}-${date.day}',
        ),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderSm,
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.lacosPurple : Colors.transparent,
              borderRadius: AppRadius.borderSm,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.purple300)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                if (hasAppointments) ...[
                  const SizedBox(height: 2),
                  Container(
                    key: Key(
                      'agenda-calendar-indicator-${date.year}-${date.month}-${date.day}',
                    ),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ] else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
