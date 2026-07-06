import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> findByDay(DateTime day);

  Future<Appointment> create(Appointment appointment);

  Future<Appointment> update(Appointment appointment);

  Future<void> delete(String appointmentId);
}
