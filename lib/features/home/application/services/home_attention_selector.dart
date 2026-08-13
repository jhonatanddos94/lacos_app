import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';

class HomeAttentionSelector {
  const HomeAttentionSelector._();

  static List<AgendaAppointmentDisplay> select(
    List<AgendaAppointmentDisplay> appointments, {
    required DateTime now,
  }) {
    final overdue = appointments
        .where(
          (appointment) =>
              appointment.operationalState(now: now) ==
              AppointmentOperationalState.overdue,
        )
        .toList(growable: false);

    return [...overdue]..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
}
