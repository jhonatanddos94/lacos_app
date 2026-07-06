import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.salonId,
    required this.ownerId,
    required this.clientId,
    required this.professionalId,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String salonId;
  final String ownerId;
  final String clientId;
  final String professionalId;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
