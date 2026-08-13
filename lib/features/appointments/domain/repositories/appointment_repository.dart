import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> findByDay(DateTime day);

  Future<List<Appointment>> findByDateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  });

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

  Future<Appointment?> findNextByClientId(
    String clientId, {
    required DateTime now,
  });

  /// Appointments cancelados da cliente no salão atual (`isActive` + status canceled).
  Future<List<Appointment>> findCanceledByClientId(String clientId);
}
