import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class AppointmentDetails {
  const AppointmentDetails({
    required this.appointment,
    required this.client,
    required this.professional,
    required this.services,
    this.notes,
  });

  final Appointment appointment;
  final Client client;
  final Professional professional;
  final List<Service> services;
  final String? notes;
}
