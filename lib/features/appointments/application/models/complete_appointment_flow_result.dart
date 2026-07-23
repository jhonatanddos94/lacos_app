import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/presentation/models/complete_appointment_success_action.dart';

class CompleteAppointmentFlowResult {
  const CompleteAppointmentFlowResult({
    required this.appointment,
    required this.successAction,
  });

  final Appointment appointment;
  final CompleteAppointmentSuccessAction successAction;
}
