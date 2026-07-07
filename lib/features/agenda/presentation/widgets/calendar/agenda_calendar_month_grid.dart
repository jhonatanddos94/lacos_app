/// Grade mensal pura para o calendário da Agenda (sem dependências de UI ou domínio).
class AgendaCalendarMonthGrid {
  AgendaCalendarMonthGrid({
    required this.year,
    required this.month,
  }) : assert(month >= 1 && month <= 12);

  final int year;
  final int month;

  static const weekdayLabels = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  factory AgendaCalendarMonthGrid.fromDate(DateTime date) {
    return AgendaCalendarMonthGrid(year: date.year, month: date.month);
  }

  AgendaCalendarMonthGrid previousMonth() {
    final date = DateTime(year, month - 1, 1);
    return AgendaCalendarMonthGrid(year: date.year, month: date.month);
  }

  AgendaCalendarMonthGrid nextMonth() {
    final date = DateTime(year, month + 1, 1);
    return AgendaCalendarMonthGrid(year: date.year, month: date.month);
  }

  String get titleLabel => '${monthName(month)} $year';

  String get previousMonthLabel => monthName(_previousMonthNumber());

  String get nextMonthLabel => monthName(_nextMonthNumber());

  AgendaCalendarVisibleRange visibleDateRange() {
    final cells = buildCells();

    return AgendaCalendarVisibleRange(
      start: normalizeCalendarDay(cells.first.date),
      end: normalizeCalendarDay(cells.last.date),
    );
  }

  List<AgendaCalendarDayCell> buildCells() {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingEmptyCells = firstDayOfMonth.weekday - DateTime.monday;

    final cells = <AgendaCalendarDayCell>[];

    if (leadingEmptyCells > 0) {
      final previous = previousMonth();
      final daysInPreviousMonth = DateTime(previous.year, previous.month + 1, 0).day;
      for (var index = leadingEmptyCells - 1; index >= 0; index--) {
        final day = daysInPreviousMonth - index;
        cells.add(
          AgendaCalendarDayCell(
            date: DateTime(previous.year, previous.month, day),
            isCurrentMonth: false,
          ),
        );
      }
    }

    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(
        AgendaCalendarDayCell(
          date: DateTime(year, month, day),
          isCurrentMonth: true,
        ),
      );
    }

    var nextMonthDay = 1;
    final next = nextMonth();
    while (cells.length % AgendaCalendarMonthGrid.weekdayLabels.length != 0) {
      cells.add(
        AgendaCalendarDayCell(
          date: DateTime(next.year, next.month, nextMonthDay),
          isCurrentMonth: false,
        ),
      );
      nextMonthDay++;
    }

    while (cells.length < 42) {
      cells.add(
        AgendaCalendarDayCell(
          date: DateTime(next.year, next.month, nextMonthDay),
          isCurrentMonth: false,
        ),
      );
      nextMonthDay++;
    }

    return cells;
  }

  int _previousMonthNumber() {
    return month == 1 ? 12 : month - 1;
  }

  int _nextMonthNumber() {
    return month == 12 ? 1 : month + 1;
  }

  static String monthName(int month) {
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
}

class AgendaCalendarDayCell {
  const AgendaCalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
  });

  final DateTime date;
  final bool isCurrentMonth;
}

class AgendaCalendarVisibleRange {
  const AgendaCalendarVisibleRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool calendarDayHasAppointments(
  DateTime day,
  Set<DateTime> daysWithAppointments,
) {
  final normalizedDay = normalizeCalendarDay(day);
  for (final appointmentDay in daysWithAppointments) {
    if (isSameCalendarDay(normalizedDay, appointmentDay)) {
      return true;
    }
  }
  return false;
}

DateTime normalizeCalendarDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
