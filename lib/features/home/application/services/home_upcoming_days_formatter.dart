import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_date_formatters.dart';

class HomeUpcomingDaysFormatter {
  const HomeUpcomingDaysFormatter._();

  static const _shortMonths = [
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'mai.',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];

  static String formatDayLabel({
    required DateTime day,
    required DateTime today,
  }) {
    final normalizedDay = normalizeAppointmentDate(day);
    final normalizedToday = normalizeAppointmentDate(today);
    final tomorrow = normalizedToday.add(const Duration(days: 1));

    if (isSameAppointmentDate(normalizedDay, tomorrow)) {
      return AppStrings.appointmentDateTomorrow;
    }

    final weekday = formatAgendaUpcomingDayWeekday(normalizedDay.weekday);
    final month = _shortMonths[normalizedDay.month - 1];
    return '$weekday, ${normalizedDay.day} $month';
  }

  static String formatCountLabel(int count) {
    if (count == 1) {
      return '1 ${AppStrings.homeAppointmentSingular}';
    }

    return '$count ${AppStrings.homeAppointmentPlural}';
  }

  static String formatSemanticsLabel({
    required DateTime day,
    required DateTime today,
    required int count,
  }) {
    final normalizedDay = normalizeAppointmentDate(day);
    final normalizedToday = normalizeAppointmentDate(today);
    final tomorrow = normalizedToday.add(const Duration(days: 1));

    final String dayLabel;
    if (isSameAppointmentDate(normalizedDay, tomorrow)) {
      dayLabel = AppStrings.appointmentDateTomorrow;
    } else {
      final weekday = fullAgendaWeekdayName(normalizedDay.weekday);
      final month = fullAgendaMonthName(normalizedDay.month);
      dayLabel = '$weekday, ${normalizedDay.day} de $month';
    }

    return '$dayLabel, ${formatCountLabel(count)}. '
        '${AppStrings.homeUpcomingDayOpenAgendaSemantic}';
  }
}
