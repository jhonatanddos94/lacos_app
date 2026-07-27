import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_operational_state_resolver.dart';
import 'package:lacos_app/features/clients/application/models/client_next_appointment_preview.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

class ClientNextAppointmentLoader {
  const ClientNextAppointmentLoader({
    required AppointmentRepository appointmentRepository,
    required AppointmentServiceRepository appointmentServiceRepository,
    required ClientRepository clientRepository,
    required ProfessionalRepository professionalRepository,
    required ServiceRepository serviceRepository,
    AppointmentOperationalStateResolver? operationalStateResolver,
  }) : _appointmentRepository = appointmentRepository,
       _appointmentServiceRepository = appointmentServiceRepository,
       _clientRepository = clientRepository,
       _professionalRepository = professionalRepository,
       _serviceRepository = serviceRepository,
       _operationalStateResolver =
           operationalStateResolver ??
           const AppointmentOperationalStateResolver();

  final AppointmentRepository _appointmentRepository;
  final AppointmentServiceRepository _appointmentServiceRepository;
  final ClientRepository _clientRepository;
  final ProfessionalRepository _professionalRepository;
  final ServiceRepository _serviceRepository;
  final AppointmentOperationalStateResolver _operationalStateResolver;

  Future<ClientNextAppointmentPreview?> load({
    required String clientId,
    required DateTime now,
  }) async {
    final appointment = await _appointmentRepository.findNextByClientId(
      clientId,
      now: now,
    );
    if (appointment == null) {
      return null;
    }

    final appointmentServices = await _appointmentServiceRepository
        .findByAppointment(appointment.id);
    final sortedServices = [...appointmentServices]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final (clients, professionals, services) = await (
      _clientRepository.findAll(),
      _professionalRepository.findAll(),
      _serviceRepository.findAll(),
    ).wait;

    final client = _findClient(clients, appointment.clientId);
    final professional = _findProfessional(
      professionals,
      appointment.professionalId,
    );
    final serviceById = {for (final service in services) service.id: service};

    final operationalState = _operationalStateResolver.resolve(
      status: appointment.status,
      startAt: appointment.startAt,
      endAt: appointment.endAt,
      now: now,
    );

    return ClientNextAppointmentPreview(
      appointmentId: appointment.id,
      clientId: appointment.clientId,
      clientName: client?.name ?? AppStrings.appointmentChooseClientPrompt,
      clientPhotoUrl: client?.photoUrl,
      professionalName:
          professional?.name ??
          AppStrings.clientNextAppointmentProfessionalUnavailable,
      servicesSummary: _buildServicesSummary(sortedServices, serviceById),
      startAt: appointment.startAt,
      endAt: appointment.endAt,
      status: appointment.status,
      operationalState: operationalState,
    );
  }

  Client? _findClient(List<Client> clients, String clientId) {
    for (final client in clients) {
      if (client.id == clientId) {
        return client;
      }
    }
    return null;
  }

  Professional? _findProfessional(
    List<Professional> professionals,
    String professionalId,
  ) {
    for (final professional in professionals) {
      if (professional.id == professionalId) {
        return professional;
      }
    }
    return null;
  }

  String _buildServicesSummary(
    List<AppointmentService> appointmentServices,
    Map<String, Service> serviceById,
  ) {
    if (appointmentServices.isEmpty) {
      return AppStrings.clientNextAppointmentServicesUnavailable;
    }

    final names = appointmentServices
        .map((item) => serviceById[item.serviceId]?.name)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    if (names.isEmpty) {
      final count = appointmentServices.length;
      return count == 1
          ? AppStrings.clientNextAppointmentSingleService
          : AppStrings.clientNextAppointmentMultipleServices(count);
    }

    if (names.length == 1) {
      return names.first;
    }

    if (names.length == 2) {
      return '${names.first} + ${names.last}';
    }

    return AppStrings.clientNextAppointmentServicesAndMore(
      names.first,
      names.length - 1,
    );
  }
}
