import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

class AgendaAppointmentDisplay {
  const AgendaAppointmentDisplay({
    required this.appointmentId,
    required this.clientName,
    required this.servicesSummary,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.clientPhotoUrl,
  });

  final String appointmentId;
  final String clientName;
  final String? clientPhotoUrl;
  final String servicesSummary;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
}
