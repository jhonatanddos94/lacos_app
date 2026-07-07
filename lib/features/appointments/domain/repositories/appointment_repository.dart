import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> findByDay(DateTime day);

  Future<Appointment> findById(String appointmentId);

  Future<Appointment> create(Appointment appointment);

  Future<Appointment> update(Appointment appointment);

  Future<Appointment> cancel(String appointmentId);

  Future<void> delete(String appointmentId);
}
