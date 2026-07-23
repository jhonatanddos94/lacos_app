import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';

class AgendaDisplaySections {
  const AgendaDisplaySections({
    this.pending = const [],
    this.completed = const [],
    this.canceled = const [],
  });

  final List<AgendaAppointmentDisplay> pending;
  final List<AgendaAppointmentDisplay> completed;
  final List<AgendaAppointmentDisplay> canceled;

  bool get isEmpty => pending.isEmpty && completed.isEmpty && canceled.isEmpty;

  bool get hasCompletedSection => completed.isNotEmpty;

  bool get hasCanceledSection => canceled.isNotEmpty;

  bool get showPendingHeader =>
      pending.isNotEmpty && (hasCompletedSection || hasCanceledSection);
}
