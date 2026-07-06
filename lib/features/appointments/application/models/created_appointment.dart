import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';

class CreatedAppointment {
  const CreatedAppointment({
    required this.appointment,
    required this.services,
  });

  final Appointment appointment;
  final List<AppointmentService> services;
}
