import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

class ClientNextAppointmentPreview {
  const ClientNextAppointmentPreview({
    required this.appointmentId,
    required this.clientId,
    required this.clientName,
    required this.professionalName,
    required this.servicesSummary,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.operationalState,
    this.clientPhotoUrl,
  });

  final String appointmentId;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String professionalName;
  final String servicesSummary;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
  final AppointmentOperationalState operationalState;

  AgendaAppointmentDisplay toAgendaDisplay() {
    return AgendaAppointmentDisplay(
      appointmentId: appointmentId,
      clientId: clientId,
      clientName: clientName,
      clientPhotoUrl: clientPhotoUrl,
      servicesSummary: servicesSummary,
      startAt: startAt,
      endAt: endAt,
      status: status,
    );
  }
}
