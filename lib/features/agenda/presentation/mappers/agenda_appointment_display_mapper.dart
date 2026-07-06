import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class AgendaAppointmentDisplayMapper {
  const AgendaAppointmentDisplayMapper._();

  static List<TodayScheduleAppointment> toScheduleItems(
    List<Appointment> appointments,
    DateTime selectedDay,
  ) {
    final sorted = [...appointments]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final nextAppointmentId = _findNextAppointmentId(sorted, selectedDay);

    return sorted
        .map(
          (appointment) => TodayScheduleAppointment(
            startTime: _formatTime(appointment.startAt),
            endTime: _formatTime(appointment.endAt),
            clientName: 'Cliente',
            serviceName: 'Serviços',
            status: _mapScheduleStatus(
              appointment,
              isNext: appointment.id == nextAppointmentId,
            ),
          ),
        )
        .toList(growable: false);
  }

  static String? nextStartTime(List<Appointment> appointments, DateTime day) {
    final sorted = [...appointments]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final nextId = _findNextAppointmentId(sorted, day);
    if (nextId == null) return null;

    final nextAppointment = sorted.firstWhere(
      (appointment) => appointment.id == nextId,
    );

    return _formatTime(nextAppointment.startAt);
  }

  static String? _findNextAppointmentId(
    List<Appointment> appointments,
    DateTime selectedDay,
  ) {
    final now = DateTime.now();
    final isToday = _isSameDay(selectedDay, now);

    for (final appointment in appointments) {
      switch (appointment.status) {
        case AppointmentStatus.completed:
        case AppointmentStatus.canceled:
          continue;
        case AppointmentStatus.pending:
        case AppointmentStatus.confirmed:
          if (isToday && appointment.startAt.isBefore(now)) {
            continue;
          }
          return appointment.id;
      }
    }

    return null;
  }

  static ScheduleStatus _mapScheduleStatus(
    Appointment appointment, {
    required bool isNext,
  }) {
    if (isNext) {
      return ScheduleStatus.next;
    }

    return switch (appointment.status) {
      AppointmentStatus.completed => ScheduleStatus.completed,
      AppointmentStatus.confirmed => ScheduleStatus.confirmed,
      AppointmentStatus.pending => ScheduleStatus.pending,
      AppointmentStatus.canceled => ScheduleStatus.canceled,
    };
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
