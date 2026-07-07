import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/loaders/appointment_details_loader.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

void main() {
  group('AppointmentDetailsLoader', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeAppointmentServiceRepository appointmentServiceRepository;
    late AppointmentDetailsLoader loader;

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      appointmentServiceRepository = _FakeAppointmentServiceRepository();
      loader = AppointmentDetailsLoader(
        appointmentRepository: appointmentRepository,
        clientRepository: _FakeClientRepository(),
        professionalRepository: _FakeProfessionalRepository(),
        appointmentServiceRepository: appointmentServiceRepository,
        serviceRepository: _FakeServiceRepository(),
      );
    });

    test('usa findById e retorna apenas serviços ativos', () async {
      appointmentRepository.appointment = _appointment();
      appointmentServiceRepository.activeServices = [
        _appointmentService(id: 'line-1', serviceId: 'service-1'),
        _appointmentService(
          id: 'line-2',
          serviceId: 'service-2',
          isActive: false,
        ),
      ];

      final details = await loader.load(
        appointmentId: 'appointment-1',
        day: DateTime(2026, 8, 21),
      );

      expect(details.services.length, 1);
      expect(details.services.first.id, 'service-1');
    });

    test('resolve serviços via snapshot quando catálogo não contém o item', () async {
      appointmentRepository.appointment = _appointment();
      appointmentServiceRepository.activeServices = [
        _appointmentService(id: 'line-1', serviceId: 'missing-service'),
      ];

      final details = await loader.load(
        appointmentId: 'appointment-1',
        day: DateTime(2026, 8, 21),
      );

      expect(details.services.length, 1);
      expect(details.services.first.id, 'missing-service');
      expect(details.services.first.durationMinutes, 60);
    });
  });
}

Appointment _appointment() {
  final day = DateTime(2026, 8, 21, 10);
  return Appointment(
    id: 'appointment-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: day,
    endAt: day.add(const Duration(hours: 1)),
    status: AppointmentStatus.pending,
    isActive: true,
    createdAt: day,
    updatedAt: day,
  );
}

AppointmentService _appointmentService({
  required String id,
  required String serviceId,
  bool isActive = true,
}) {
  final now = DateTime(2026, 8, 21);
  return AppointmentService(
    id: id,
    appointmentId: 'appointment-1',
    serviceId: serviceId,
    salonId: 'salon-1',
    ownerId: 'owner-1',
    priceAtBooking: 80,
    durationMinutesAtBooking: 60,
    displayOrder: 0,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;

  @override
  Future<Appointment> findById(String appointmentId) async => appointment!;

  @override
  Future<List<Appointment>> findByDay(DateTime day) async => [appointment!];

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async =>
      const {};

  @override
  Future<Appointment> cancel({
    required String appointmentId,
    required AppointmentCanceledBy canceledBy,
    String? cancellationReason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> complete(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> create(Appointment appointment) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}

class _FakeAppointmentServiceRepository implements AppointmentServiceRepository {
  List<AppointmentService> activeServices = const [];

  @override
  Future<List<AppointmentService>> findByAppointment(String appointmentId) async {
    return activeServices;
  }

  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) {
    throw UnimplementedError();
  }
}

class _FakeClientRepository implements ClientRepository {
  @override
  Future<List<Client>> findAll() async => [
    Client(
      id: 'client-1',
      name: 'Ana',
      phone: '11999999999',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfessionalRepository implements ProfessionalRepository {
  @override
  Future<List<Professional>> findAll() async => [
    Professional(
      id: 'professional-1',
      name: 'Maria',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeServiceRepository implements ServiceRepository {
  @override
  Future<List<Service>> findAll() async => [
    Service(
      id: 'service-1',
      name: 'Corte',
      durationMinutes: 60,
      price: 80,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
