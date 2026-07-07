import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_display_sections.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

class AgendaDisplayOrganizer {
  const AgendaDisplayOrganizer._();

  static AgendaDisplaySections organize(
    List<AgendaAppointmentDisplay> appointments,
  ) {
    final sorted = [...appointments]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final pending = <AgendaAppointmentDisplay>[];
    final completed = <AgendaAppointmentDisplay>[];
    final canceled = <AgendaAppointmentDisplay>[];

    for (final appointment in sorted) {
      switch (appointment.status) {
        case AppointmentStatus.pending:
        case AppointmentStatus.confirmed:
          pending.add(appointment);
        case AppointmentStatus.completed:
          completed.add(appointment);
        case AppointmentStatus.canceled:
          canceled.add(appointment);
      }
    }

    return AgendaDisplaySections(
      pending: pending,
      completed: completed,
      canceled: canceled,
    );
  }
}
