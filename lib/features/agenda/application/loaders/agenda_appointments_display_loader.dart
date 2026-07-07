import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

class AgendaAppointmentsDisplayLoader {
  const AgendaAppointmentsDisplayLoader({
    required AppointmentRepository appointmentRepository,
    required AppointmentServiceRepository appointmentServiceRepository,
    required ClientRepository clientRepository,
    required ServiceRepository serviceRepository,
  }) : _appointmentRepository = appointmentRepository,
       _appointmentServiceRepository = appointmentServiceRepository,
       _clientRepository = clientRepository,
       _serviceRepository = serviceRepository;

  final AppointmentRepository _appointmentRepository;
  final AppointmentServiceRepository _appointmentServiceRepository;
  final ClientRepository _clientRepository;
  final ServiceRepository _serviceRepository;

  Future<List<AgendaAppointmentDisplay>> loadForDay(DateTime day) async {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final appointments = await _appointmentRepository.findByDay(normalizedDay);
    if (appointments.isEmpty) {
      return const [];
    }

    final appointmentIds = appointments
        .map((appointment) => appointment.id)
        .toList(growable: false);

    final (clients, services, appointmentServices) = await (
      _clientRepository.findAll(),
      _serviceRepository.findAll(),
      _appointmentServiceRepository.findByAppointments(appointmentIds),
    ).wait;

    final clientById = {for (final client in clients) client.id: client};
    final serviceById = {for (final service in services) service.id: service};
    final appointmentServicesByAppointmentId =
        _groupAppointmentServicesByAppointmentId(appointmentServices);

    final displays = appointments
        .map((appointment) {
          final client = clientById[appointment.clientId];
          final sortedServices = <AppointmentService>[
            ...appointmentServicesByAppointmentId[appointment.id] ?? const [],
          ]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

          return AgendaAppointmentDisplay(
            appointmentId: appointment.id,
            clientName: client?.name ?? 'Cliente',
            clientPhotoUrl: client?.photoUrl,
            servicesSummary: _buildServicesSummary(sortedServices, serviceById),
            startAt: appointment.startAt,
            endAt: appointment.endAt,
            status: appointment.status,
            canceledBy: appointment.canceledBy,
            cancellationReason: appointment.cancellationReason,
          );
        })
        .toList(growable: false);

    displays.sort((a, b) => a.startAt.compareTo(b.startAt));
    return displays;
  }

  Map<String, List<AppointmentService>> _groupAppointmentServicesByAppointmentId(
    List<AppointmentService> appointmentServices,
  ) {
    final grouped = <String, List<AppointmentService>>{};

    for (final appointmentService in appointmentServices) {
      grouped
          .putIfAbsent(appointmentService.appointmentId, () => [])
          .add(appointmentService);
    }

    return grouped;
  }

  String _buildServicesSummary(
    List<AppointmentService> appointmentServices,
    Map<String, Service> serviceById,
  ) {
    if (appointmentServices.isEmpty) {
      return 'Serviços';
    }

    final names = appointmentServices
        .map((item) => serviceById[item.serviceId]?.name)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    if (names.isEmpty) {
      final count = appointmentServices.length;
      return count == 1 ? '1 serviço' : '$count serviços';
    }

    if (names.length == 1) {
      return names.first;
    }

    return names.join(' • ');
  }
}
