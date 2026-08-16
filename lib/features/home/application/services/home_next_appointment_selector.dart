import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';

class HomeNextAppointmentSelector {
  const HomeNextAppointmentSelector._();

  /// Primeiro `current`; senão o `upcoming` mais cedo por `startAt`.
  /// Ignora completed, canceled e overdue.
  static AgendaAppointmentDisplay? select(
    List<AgendaAppointmentDisplay> appointments, {
    required DateTime now,
  }) {
    final sorted = [...appointments]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    AgendaAppointmentDisplay? firstUpcoming;

    for (final appointment in sorted) {
      switch (appointment.operationalState(now: now)) {
        case AppointmentOperationalState.current:
          return appointment;
        case AppointmentOperationalState.upcoming:
          firstUpcoming ??= appointment;
        case AppointmentOperationalState.overdue:
        case AppointmentOperationalState.completed:
        case AppointmentOperationalState.canceled:
          break;
      }
    }

    return firstUpcoming;
  }

  /// `upcoming` mais cedo por `startAt`, ignorando o que já está em andamento.
  /// Usado pelo resumo HOJE para não apontar "Próximo às" para o atual.
  static AgendaAppointmentDisplay? selectUpcoming(
    List<AgendaAppointmentDisplay> appointments, {
    required DateTime now,
  }) {
    final upcoming =
        appointments
            .where(
              (appointment) =>
                  appointment.operationalState(now: now) ==
                  AppointmentOperationalState.upcoming,
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return upcoming.isEmpty ? null : upcoming.first;
  }
}
