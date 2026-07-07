import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';

/// Datas anteriores a hoje são apenas consulta histórica.
bool isPastAgendaDay(DateTime day) {
  final normalizedDay = normalizeAppointmentDate(day);
  final today = normalizeAppointmentDate(DateTime.now());
  return normalizedDay.isBefore(today);
}

/// Datas de hoje ou futuras permitem criar e operar agendamentos.
bool isOperationalAgendaDay(DateTime day) => !isPastAgendaDay(day);
