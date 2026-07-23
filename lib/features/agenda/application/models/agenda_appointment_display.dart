import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_operational_state_resolver.dart';

class AgendaAppointmentDisplay {
  const AgendaAppointmentDisplay({
    required this.appointmentId,
    required this.clientId,
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
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String servicesSummary;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
  final AppointmentCanceledBy? canceledBy;
  final String? cancellationReason;

  static const _operationalStateResolver = AppointmentOperationalStateResolver();

  AppointmentOperationalState operationalState({DateTime? now}) {
    return _operationalStateResolver.resolve(
      status: status,
      startAt: startAt,
      endAt: endAt,
      now: now ?? DateTime.now(),
    );
  }
}
