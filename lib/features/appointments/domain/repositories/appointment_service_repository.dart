import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';

abstract interface class AppointmentServiceRepository {
  Future<List<AppointmentService>> findByAppointment(String appointmentId);

  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  });

  Future<void> deleteByAppointment(String appointmentId);
}
