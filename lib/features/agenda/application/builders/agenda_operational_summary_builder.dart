import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';

class AgendaOperationalSummaryBuilder {
  const AgendaOperationalSummaryBuilder._();

  static AgendaOperationalSummary build(
    List<AgendaAppointmentDisplay> appointments, {
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    var upcomingCount = 0;
    var currentCount = 0;
    var overdueCount = 0;
    var completedCount = 0;
    var canceledCount = 0;

    for (final appointment in appointments) {
      switch (appointment.operationalState(now: referenceNow)) {
        case AppointmentOperationalState.upcoming:
          upcomingCount++;
        case AppointmentOperationalState.current:
          currentCount++;
        case AppointmentOperationalState.overdue:
          overdueCount++;
        case AppointmentOperationalState.completed:
          completedCount++;
        case AppointmentOperationalState.canceled:
          canceledCount++;
      }
    }

    return AgendaOperationalSummary(
      upcomingCount: upcomingCount,
      currentCount: currentCount,
      overdueCount: overdueCount,
      completedCount: completedCount,
      canceledCount: canceledCount,
    );
  }
}
