import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';

/// Datas anteriores a hoje são apenas consulta histórica.
bool isPastAgendaDay(DateTime day, {DateTime? today}) {
  final normalizedDay = normalizeAppointmentDate(day);
  final referenceToday = normalizeAppointmentDate(today ?? DateTime.now());
  return normalizedDay.isBefore(referenceToday);
}

/// Datas de hoje ou futuras permitem criar e operar agendamentos.
bool isOperationalAgendaDay(DateTime day, {DateTime? today}) {
  return !isPastAgendaDay(day, today: today);
}
