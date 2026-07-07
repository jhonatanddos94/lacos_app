import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';

class CancelAppointmentParams {
  const CancelAppointmentParams({
    required this.appointmentId,
    required this.canceledBy,
    this.cancellationReason,
  });

  final String appointmentId;
  final AppointmentCanceledBy canceledBy;
  final String? cancellationReason;
}
