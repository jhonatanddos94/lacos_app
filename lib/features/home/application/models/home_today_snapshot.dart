import 'package:lacos_app/features/agenda/application/builders/agenda_operational_summary_builder.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';
import 'package:lacos_app/features/home/application/services/home_attention_selector.dart';
import 'package:lacos_app/features/home/application/services/home_next_appointment_selector.dart';

class HomeTodaySnapshot {
  const HomeTodaySnapshot({
    required this.appointments,
    required this.summary,
    required this.nextAppointment,
    required this.overdueAppointments,
  });

  factory HomeTodaySnapshot.fromAppointments(
    List<AgendaAppointmentDisplay> appointments, {
    required DateTime now,
  }) {
    return HomeTodaySnapshot(
      appointments: appointments,
      summary: AgendaOperationalSummaryBuilder.build(appointments, now: now),
      nextAppointment: HomeNextAppointmentSelector.select(
        appointments,
        now: now,
      ),
      overdueAppointments: HomeAttentionSelector.select(appointments, now: now),
    );
  }

  final List<AgendaAppointmentDisplay> appointments;
  final AgendaOperationalSummary summary;
  final AgendaAppointmentDisplay? nextAppointment;
  final List<AgendaAppointmentDisplay> overdueAppointments;

  int get totalCount => appointments.length;
}
