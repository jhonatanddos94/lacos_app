/// Identificador do mês exibido no calendário mensual da Agenda.
class AgendaCalendarView {
  const AgendaCalendarView({required this.year, required this.month})
    : assert(month >= 1 && month <= 12);

  final int year;
  final int month;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AgendaCalendarView &&
            year == other.year &&
            month == other.month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}
