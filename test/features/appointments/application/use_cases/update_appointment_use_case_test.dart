import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/use_cases/update_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  group('UpdateAppointmentUseCase', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeAppointmentServiceRepository appointmentServiceRepository;
    late UpdateAppointmentUseCase useCase;

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      appointmentServiceRepository = _FakeAppointmentServiceRepository();
      useCase = UpdateAppointmentUseCase(
        appointmentRepository: appointmentRepository,
        appointmentServiceRepository: appointmentServiceRepository,
        availabilityEngine: const AvailabilityEngine(),
      );
    });

    test('atualiza appointment e sincroniza serviços', () async {
      final startAt = DateTime(2026, 8, 21, 10);
      final endAt = startAt.add(const Duration(minutes: 60));

      appointmentRepository.appointment = _appointment(
        status: AppointmentStatus.pending,
        startAt: startAt,
        endAt: endAt,
      );
      appointmentRepository.dayAppointments = [appointmentRepository.appointment!];

      final result = await useCase(
        UpdateAppointmentParams(
          appointmentId: 'appointment-1',
          clientId: 'client-2',
          professionalId: 'professional-1',
          services: [_service(name: 'Coloração')],
          startAt: startAt,
          endAt: endAt,
          notes: 'Observação atualizada',
        ),
      );

      expect(result.appointment.clientId, 'client-2');
      expect(result.appointment.notes, 'Observação atualizada');
      expect(appointmentRepository.updateCalls, 1);
      expect(appointmentServiceRepository.deactivateCalls, 1);
      expect(appointmentServiceRepository.createManyCalls, 1);
      expect(result.services, isNotEmpty);
    });

    test('permite manter o mesmo horário ignorando o próprio appointment', () async {
      final startAt = DateTime(2026, 8, 21, 10);
      final endAt = startAt.add(const Duration(minutes: 60));
      final existing = _appointment(
        status: AppointmentStatus.confirmed,
        startAt: startAt,
        endAt: endAt,
      );

      appointmentRepository.appointment = existing;
      appointmentRepository.dayAppointments = [existing];

      final result = await useCase(
        UpdateAppointmentParams(
          appointmentId: existing.id,
          clientId: existing.clientId,
          professionalId: existing.professionalId,
          services: [_service()],
          startAt: startAt,
          endAt: endAt,
        ),
      );

      expect(result.appointment.id, existing.id);
      expect(appointmentRepository.updateCalls, 1);
    });

    test('bloqueia edição de appointment concluído', () async {
      appointmentRepository.appointment = _appointment(
        status: AppointmentStatus.completed,
      );

      await expectLater(
        useCase(
          UpdateAppointmentParams(
            appointmentId: 'appointment-1',
            clientId: 'client-1',
            professionalId: 'professional-1',
            services: [_service()],
            startAt: DateTime(2026, 8, 21, 10),
            endAt: DateTime(2026, 8, 21, 11),
          ),
        ),
        throwsA(isA<AppointmentCannotEditException>()),
      );

      expect(appointmentRepository.updateCalls, 0);
    });

    test('bloqueia edição de appointment cancelado', () async {
      appointmentRepository.appointment = _appointment(
        status: AppointmentStatus.canceled,
      );

      await expectLater(
        useCase(
          UpdateAppointmentParams(
            appointmentId: 'appointment-1',
            clientId: 'client-1',
            professionalId: 'professional-1',
            services: [_service()],
            startAt: DateTime(2026, 8, 21, 10),
            endAt: DateTime(2026, 8, 21, 11),
          ),
        ),
        throwsA(isA<AppointmentCannotEditException>()),
      );
    });

    test('não desativa serviços quando lista nova está vazia', () async {
      appointmentRepository.appointment = _appointment();

      await expectLater(
        useCase(
          UpdateAppointmentParams(
            appointmentId: 'appointment-1',
            clientId: 'client-1',
            professionalId: 'professional-1',
            services: const [],
            startAt: DateTime(2026, 8, 21, 10),
            endAt: DateTime(2026, 8, 21, 11),
          ),
        ),
        throwsA(isA<AppointmentValidationException>()),
      );

      expect(appointmentRepository.updateCalls, 0);
      expect(appointmentServiceRepository.deactivateCalls, 0);
      expect(appointmentServiceRepository.createManyCalls, 0);
    });

    test('permite editar o mesmo appointment duas vezes seguidas', () async {
      final startAt = DateTime(2026, 8, 21, 10);
      final endAt = startAt.add(const Duration(minutes: 60));
      final existing = _appointment(
        status: AppointmentStatus.pending,
        startAt: startAt,
        endAt: endAt,
      );

      appointmentRepository.appointment = existing;
      appointmentRepository.dayAppointments = [existing];
      appointmentServiceRepository.seedActive(
        _appointmentServiceLine(displayOrder: 0),
      );

      final params = UpdateAppointmentParams(
        appointmentId: existing.id,
        clientId: existing.clientId,
        professionalId: existing.professionalId,
        services: [_service()],
        startAt: startAt,
        endAt: endAt,
      );

      await useCase(params);
      final secondResult = await useCase(params);

      expect(appointmentRepository.updateCalls, 2);
      expect(appointmentServiceRepository.deactivateCalls, 2);
      expect(appointmentServiceRepository.createManyCalls, 2);
      expect(appointmentServiceRepository.activeServices.length, 1);
      expect(appointmentServiceRepository.activeServices.first.isActive, isTrue);
      expect(secondResult.services, isNotEmpty);
    });

    test('findByAppointment retorna apenas serviços ativos após sync', () async {
      final startAt = DateTime(2026, 8, 21, 10);
      final endAt = startAt.add(const Duration(minutes: 60));
      final existing = _appointment(startAt: startAt, endAt: endAt);

      appointmentRepository.appointment = existing;
      appointmentRepository.dayAppointments = [existing];
      appointmentServiceRepository.seedActive(
        _appointmentServiceLine(displayOrder: 0, label: 'old'),
      );

      await useCase(
        UpdateAppointmentParams(
          appointmentId: existing.id,
          clientId: existing.clientId,
          professionalId: existing.professionalId,
          services: [_service(name: 'Novo')],
          startAt: startAt,
          endAt: endAt,
        ),
      );

      final activeServices =
          await appointmentServiceRepository.findByAppointment(existing.id);

      expect(activeServices.length, 1);
      expect(activeServices.every((service) => service.isActive), isTrue);
      expect(
        appointmentServiceRepository.deactivatedServices.every(
          (service) => !service.isActive,
        ),
        isTrue,
      );
    });

    test('falha clara quando createMany falha após desativar antigos', () async {
      appointmentRepository.appointment = _appointment();
      appointmentRepository.dayAppointments = [appointmentRepository.appointment!];
      appointmentServiceRepository.shouldFailCreateMany = true;

      await expectLater(
        useCase(
          UpdateAppointmentParams(
            appointmentId: 'appointment-1',
            clientId: 'client-1',
            professionalId: 'professional-1',
            services: [_service()],
            startAt: DateTime(2026, 8, 21, 10),
            endAt: DateTime(2026, 8, 21, 11),
          ),
        ),
        throwsA(isA<AppointmentServicesUpdateException>()),
      );

      expect(appointmentRepository.updateCalls, 1);
      expect(appointmentServiceRepository.deactivateCalls, 1);
      expect(appointmentServiceRepository.createManyCalls, 1);
      expect(appointmentServiceRepository.activeServices, isEmpty);
    });

    test('bloqueia horário indisponível de outro appointment', () async {
      final startAt = DateTime(2026, 8, 21, 10);
      final endAt = startAt.add(const Duration(minutes: 60));

      appointmentRepository.appointment = _appointment(
        id: 'appointment-1',
        status: AppointmentStatus.pending,
        startAt: startAt,
        endAt: endAt,
      );
      appointmentRepository.dayAppointments = [
        appointmentRepository.appointment!,
        _appointment(
          id: 'appointment-2',
          status: AppointmentStatus.confirmed,
          startAt: startAt,
          endAt: endAt,
        ),
      ];

      await expectLater(
        useCase(
          UpdateAppointmentParams(
            appointmentId: 'appointment-1',
            clientId: 'client-1',
            professionalId: 'professional-1',
            services: [_service()],
            startAt: startAt,
            endAt: endAt,
          ),
        ),
        throwsA(isA<AppointmentUnavailableException>()),
      );
    });
  });
}

Service _service({String name = 'Corte'}) {
  final now = DateTime(2026, 1, 1);

  return Service(
    id: 'service-1',
    name: name,
    durationMinutes: 60,
    price: 80,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Appointment _appointment({
  String id = 'appointment-1',
  AppointmentStatus status = AppointmentStatus.pending,
  DateTime? startAt,
  DateTime? endAt,
}) {
  final now = DateTime(2026, 8, 21);
  final start = startAt ?? DateTime(2026, 8, 21, 10);
  final end = endAt ?? start.add(const Duration(minutes: 60));

  return Appointment(
    id: id,
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: start,
    endAt: end,
    status: status,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;
  List<Appointment> dayAppointments = const [];
  var updateCalls = 0;

  @override
  Future<Appointment> findById(String appointmentId) async {
    final current = appointment;
    if (current == null) {
      throw const AppointmentNotFoundException();
    }
    return current;
  }

  @override
  Future<List<Appointment>> findByDay(DateTime day) async {
    return dayAppointments;
  }

  @override
  Future<Appointment> update(Appointment appointment) async {
    updateCalls++;
    this.appointment = appointment;
    return appointment;
  }

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
}

class _FakeAppointmentServiceRepository implements AppointmentServiceRepository {
  var deactivateCalls = 0;
  var createManyCalls = 0;
  var shouldFailCreateMany = false;
  final activeServices = <AppointmentService>[];
  final deactivatedServices = <AppointmentService>[];

  void seedActive(AppointmentService service) {
    activeServices
      ..clear()
      ..add(service);
    deactivatedServices.clear();
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) async {
    deactivateCalls++;
    deactivatedServices.addAll(
      activeServices.map(
        (service) => AppointmentService(
          id: service.id,
          appointmentId: service.appointmentId,
          serviceId: service.serviceId,
          salonId: service.salonId,
          ownerId: service.ownerId,
          priceAtBooking: service.priceAtBooking,
          durationMinutesAtBooking: service.durationMinutesAtBooking,
          displayOrder: service.displayOrder,
          isActive: false,
          createdAt: service.createdAt,
          updatedAt: service.updatedAt,
        ),
      ),
    );
    activeServices.clear();
  }

  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) async {
    createManyCalls++;
    if (shouldFailCreateMany) {
      throw StateError('createMany failed');
    }

    final created = services
        .map(
          (service) => AppointmentService(
            id: 'service-line-${service.displayOrder}-$createManyCalls',
            appointmentId: appointmentId,
            serviceId: service.serviceId,
            salonId: service.salonId,
            ownerId: service.ownerId,
            priceAtBooking: service.priceAtBooking,
            durationMinutesAtBooking: service.durationMinutesAtBooking,
            displayOrder: service.displayOrder,
            isActive: true,
            createdAt: service.createdAt,
            updatedAt: service.updatedAt,
          ),
        )
        .toList(growable: false);

    activeServices
      ..clear()
      ..addAll(created);

    return created;
  }

  @override
  Future<List<AppointmentService>> findByAppointment(String appointmentId) async {
    return activeServices.where((service) => service.isActive).toList(growable: false);
  }

  @override
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) {
    throw UnimplementedError();
  }
}

AppointmentService _appointmentServiceLine({
  required int displayOrder,
  String label = 'seed',
}) {
  final now = DateTime(2026, 8, 21);
  return AppointmentService(
    id: 'seed-$label',
    appointmentId: 'appointment-1',
    serviceId: 'service-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    priceAtBooking: 80,
    durationMinutesAtBooking: 60,
    displayOrder: displayOrder,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
