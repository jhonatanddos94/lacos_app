import 'package:flutter/material.dart';

import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_day_status.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_chip.dart';

class AgendaDaySelector extends StatelessWidget {
  const AgendaDaySelector({
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xxs),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = isSameAppointmentDate(day, selectedDay);
          final isToday = isSameAppointmentDate(day, DateTime.now());
          final isPast = isPastAgendaDay(day);

          return AgendaDayChip(
            day: day,
            isSelected: isSelected,
            isToday: isToday,
            isPast: isPast,
            onTap: () => onDaySelected(day),
          );
        },
      ),
    );
  }
}
