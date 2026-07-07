import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> findByDay(DateTime day);

  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  });

  Future<Appointment> findById(String appointmentId);

  Future<Appointment> create(Appointment appointment);

  Future<Appointment> update(Appointment appointment);

  Future<Appointment> cancel({
    required String appointmentId,
    required AppointmentCanceledBy canceledBy,
    String? cancellationReason,
  });

  Future<Appointment> complete(String appointmentId);

  Future<void> delete(String appointmentId);
}
