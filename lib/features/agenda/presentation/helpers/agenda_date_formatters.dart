import 'package:lacos_app/core/config/app_strings.dart';

String formatAgendaDateLine(
  DateTime day, {
  required bool isToday,
  bool isPastDay = false,
}) {
  final weekday = fullAgendaWeekdayName(day.weekday);
  final dayNumber = day.day.toString().padLeft(2, '0');
  final month = fullAgendaMonthName(day.month);
  final formattedDate = '$weekday, $dayNumber de $month';

  if (isToday) {
    return 'Hoje • $formattedDate';
  }

  if (isPastDay) {
    return '${AppStrings.agendaHistoricalDayLabel} • $formattedDate';
  }

  return formattedDate;
}

String formatAgendaShortWeekday(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Seg',
    DateTime.tuesday => 'Ter',
    DateTime.wednesday => 'Qua',
    DateTime.thursday => 'Qui',
    DateTime.friday => 'Sex',
    DateTime.saturday => 'Sáb',
    DateTime.sunday => 'Dom',
    _ => '',
  };
}

String fullAgendaWeekdayName(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Segunda-feira',
    DateTime.tuesday => 'Terça-feira',
    DateTime.wednesday => 'Quarta-feira',
    DateTime.thursday => 'Quinta-feira',
    DateTime.friday => 'Sexta-feira',
    DateTime.saturday => 'Sábado',
    DateTime.sunday => 'Domingo',
    _ => '',
  };
}

String fullAgendaMonthName(int month) {
  return switch (month) {
    1 => 'Janeiro',
    2 => 'Fevereiro',
    3 => 'Março',
    4 => 'Abril',
    5 => 'Maio',
    6 => 'Junho',
    7 => 'Julho',
    8 => 'Agosto',
    9 => 'Setembro',
    10 => 'Outubro',
    11 => 'Novembro',
    12 => 'Dezembro',
    _ => '',
  };
}
