import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

class HomeOperationalBoundary {
  const HomeOperationalBoundary._();

  /// Próxima fronteira temporal usada pelas regras de current/upcoming/overdue.
  ///
  /// `startAt` transiciona upcoming → current.
  /// `endAt` transiciona current → overdue.
  /// Completed e canceled não geram fronteira.
  static DateTime? next({
    required List<AgendaAppointmentDisplay> appointments,
    required DateTime now,
  }) {
    DateTime? upcomingBoundary;

    for (final appointment in appointments) {
      if (!_isActive(appointment.status)) {
        continue;
      }

      final candidate = _boundaryFor(appointment, now);
      if (candidate == null) {
        continue;
      }

      if (upcomingBoundary == null || candidate.isBefore(upcomingBoundary)) {
        upcomingBoundary = candidate;
      }
    }

    return upcomingBoundary;
  }

  static bool _isActive(AppointmentStatus status) {
    return status == AppointmentStatus.pending ||
        status == AppointmentStatus.confirmed;
  }

  static DateTime? _boundaryFor(
    AgendaAppointmentDisplay appointment,
    DateTime now,
  ) {
    if (now.isBefore(appointment.startAt)) {
      return appointment.startAt;
    }

    if (now.isBefore(appointment.endAt)) {
      return appointment.endAt;
    }

    return null;
  }
}
