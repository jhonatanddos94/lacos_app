import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

String formatAppointmentDateLabel(DateTime date) {
  const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');

  return '$weekday, $day de $month';
}

DateTime normalizeAppointmentDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime toAppointmentLocalTime(DateTime dateTime) {
  return dateTime.toLocal();
}

String formatAppointmentClockTime(DateTime dateTime) {
  final local = toAppointmentLocalTime(dateTime);
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatAppointmentDuration(DateTime startAt, DateTime endAt) {
  final minutes = endAt.difference(startAt).inMinutes;
  if (minutes <= 0) {
    return '';
  }

  if (minutes < 60) {
    return '${minutes}min';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (remainingMinutes == 0) {
    return '${hours}h';
  }

  if (remainingMinutes == 30) {
    return '${hours}h30';
  }

  final remainingLabel = remainingMinutes.toString().padLeft(2, '0');
  return '${hours}h$remainingLabel';
}

bool isSameAppointmentDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatAppointmentStatusLabel(AppointmentStatus status) {
  return switch (status) {
    AppointmentStatus.pending => 'Pendente',
    AppointmentStatus.confirmed => 'Confirmado',
    AppointmentStatus.completed => 'Concluído',
    AppointmentStatus.canceled => 'Cancelado',
  };
}

String formatAppointmentDateTimeRange(DateTime startAt, DateTime endAt) {
  final dateLabel = formatAppointmentDateLabel(startAt);
  final startTime = formatAppointmentClockTime(startAt);
  final endTime = formatAppointmentClockTime(endAt);

  return '$dateLabel • $startTime – $endTime';
}
