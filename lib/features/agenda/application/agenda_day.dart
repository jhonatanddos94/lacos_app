import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';

/// Chave estável para providers da Agenda indexados por dia.
class AgendaDay {
  const AgendaDay({required this.year, required this.month, required this.day});

  factory AgendaDay.from(DateTime date) {
    final normalized = normalizeAppointmentDate(date);
    return AgendaDay(
      year: normalized.year,
      month: normalized.month,
      day: normalized.day,
    );
  }

  final int year;
  final int month;
  final int day;

  DateTime toDateTime() => DateTime(year, month, day);

  @override
  bool operator ==(Object other) {
    return other is AgendaDay &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);
}
