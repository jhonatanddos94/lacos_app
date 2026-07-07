import 'package:lacos_app/features/appointments/application/models/cancel_appointment_params.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';

class CancelAppointmentUseCase {
  const CancelAppointmentUseCase({
    required AppointmentRepository appointmentRepository,
  }) : _appointmentRepository = appointmentRepository;

  final AppointmentRepository _appointmentRepository;

  Future<Appointment> call(CancelAppointmentParams params) async {
    final appointment = await _appointmentRepository.findById(
      params.appointmentId,
    );

    if (appointment.status == AppointmentStatus.completed) {
      throw const AppointmentCannotCancelCompletedException();
    }

    if (appointment.status == AppointmentStatus.canceled) {
      return appointment;
    }

    return _appointmentRepository.cancel(
      appointmentId: params.appointmentId,
      canceledBy: params.canceledBy,
      cancellationReason: params.cancellationReason,
    );
  }
}
