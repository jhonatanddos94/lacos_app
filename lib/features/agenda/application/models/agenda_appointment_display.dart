import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
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
    this.canceledBy,
    this.cancellationReason,
  });

  final String appointmentId;
  final String clientName;
  final String? clientPhotoUrl;
  final String servicesSummary;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
  final AppointmentCanceledBy? canceledBy;
  final String? cancellationReason;
}
