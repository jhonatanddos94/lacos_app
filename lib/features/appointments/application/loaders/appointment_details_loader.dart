import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

class AppointmentDetailsLoader {
  const AppointmentDetailsLoader({
    required AppointmentRepository appointmentRepository,
    required ClientRepository clientRepository,
    required ProfessionalRepository professionalRepository,
    required AppointmentServiceRepository appointmentServiceRepository,
    required ServiceRepository serviceRepository,
  }) : _appointmentRepository = appointmentRepository,
       _clientRepository = clientRepository,
       _professionalRepository = professionalRepository,
       _appointmentServiceRepository = appointmentServiceRepository,
       _serviceRepository = serviceRepository;

  final AppointmentRepository _appointmentRepository;
  final ClientRepository _clientRepository;
  final ProfessionalRepository _professionalRepository;
  final AppointmentServiceRepository _appointmentServiceRepository;
  final ServiceRepository _serviceRepository;

  Future<AppointmentDetails> load({
    required String appointmentId,
    required DateTime day,
  }) async {
    final normalizedDay = DateTime(day.year, day.month, day.day);

    final (
      appointments,
      appointmentServices,
      clients,
      professionals,
      services,
    ) = await (
      _appointmentRepository.findByDay(normalizedDay),
      _appointmentServiceRepository.findByAppointment(appointmentId),
      _clientRepository.findAll(),
      _professionalRepository.findAll(),
      _serviceRepository.findAll(),
    ).wait;

    final appointment = _findAppointment(appointments, appointmentId);
    if (appointment == null) {
      throw StateError('Agendamento não encontrado.');
    }

    final clientById = {for (final client in clients) client.id: client};
    final professionalById = {
      for (final professional in professionals) professional.id: professional,
    };
    final serviceById = {for (final service in services) service.id: service};

    final client = clientById[appointment.clientId];
    if (client == null) {
      throw StateError('Cliente não encontrada.');
    }

    final professional = professionalById[appointment.professionalId];
    if (professional == null) {
      throw StateError('Profissional não encontrada.');
    }

    final resolvedServices = _resolveServices(
      appointmentServices: appointmentServices,
      serviceById: serviceById,
    );

    return AppointmentDetails(
      appointment: appointment,
      client: client,
      professional: professional,
      services: resolvedServices,
      notes: appointment.notes,
    );
  }

  Appointment? _findAppointment(
    List<Appointment> appointments,
    String appointmentId,
  ) {
    for (final appointment in appointments) {
      if (appointment.id == appointmentId) {
        return appointment;
      }
    }

    return null;
  }

  List<Service> _resolveServices({
    required List<AppointmentService> appointmentServices,
    required Map<String, Service> serviceById,
  }) {
    final sorted = [...appointmentServices]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return sorted
        .map((item) => serviceById[item.serviceId])
        .whereType<Service>()
        .toList(growable: false);
  }
}
