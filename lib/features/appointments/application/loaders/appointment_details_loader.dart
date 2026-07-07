import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
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
    final (
      appointment,
      appointmentServices,
      clients,
      professionals,
      services,
    ) = await (
      _appointmentRepository.findById(appointmentId),
      _appointmentServiceRepository.findByAppointment(appointmentId),
      _clientRepository.findAll(),
      _professionalRepository.findAll(),
      _serviceRepository.findAll(),
    ).wait;

    if (!appointment.isActive) {
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

  List<Service> _resolveServices({
    required List<AppointmentService> appointmentServices,
    required Map<String, Service> serviceById,
  }) {
    final activeServices = appointmentServices
        .where((item) => item.isActive)
        .toList();
    activeServices.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return activeServices
        .map(
          (item) =>
              serviceById[item.serviceId] ??
              _serviceFromBookingSnapshot(item),
        )
        .toList(growable: false);
  }

  Service _serviceFromBookingSnapshot(AppointmentService item) {
    return Service(
      id: item.serviceId,
      name: 'Serviço',
      durationMinutes: item.durationMinutesAtBooking,
      price: item.priceAtBooking,
      isActive: true,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }
}
