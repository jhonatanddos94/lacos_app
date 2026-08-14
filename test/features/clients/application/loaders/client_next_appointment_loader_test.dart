import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/clients/application/loaders/client_next_appointment_loader.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

void main() {
  group('ClientNextAppointmentLoader', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeAppointmentServiceRepository appointmentServiceRepository;
    late ClientNextAppointmentLoader loader;
    final now = DateTime(2026, 7, 14, 15);

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      appointmentServiceRepository = _FakeAppointmentServiceRepository();
      loader = ClientNextAppointmentLoader(
        appointmentRepository: appointmentRepository,
        appointmentServiceRepository: appointmentServiceRepository,
        clientRepository: _FakeClientRepository(),
        professionalRepository: _FakeProfessionalRepository(),
        serviceRepository: _FakeServiceRepository(),
      );
    });

    test('retorna null quando não existe próximo appointment', () async {
      appointmentRepository.nextAppointment = null;

      final preview = await loader.load(clientId: 'client-1', now: now);

      expect(preview, isNull);
    });

    test('resolve profissional, serviços e estado operacional', () async {
      final startAt = now.add(const Duration(minutes: 30));
      final endAt = startAt.add(const Duration(hours: 1));
      appointmentRepository.nextAppointment = _appointment(
        startAt: startAt,
        endAt: endAt,
      );
      appointmentServiceRepository.services = [
        _appointmentService(serviceId: 'service-1', displayOrder: 0),
        _appointmentService(serviceId: 'service-2', displayOrder: 1),
      ];

      final preview = await loader.load(clientId: 'client-1', now: now);

      expect(preview, isNotNull);
      expect(preview!.professionalName, 'Maria');
      expect(preview.servicesSummary, 'Corte + Coloração');
      expect(preview.operationalState, AppointmentOperationalState.upcoming);
    });

    test('usa fallback quando referências estão ausentes', () async {
      final startAt = now.subtract(const Duration(minutes: 15));
      final endAt = startAt.add(const Duration(hours: 1));
      appointmentRepository.nextAppointment = _appointment(
        professionalId: 'missing-professional',
        startAt: startAt,
        endAt: endAt,
      );
      appointmentServiceRepository.services = [
        _appointmentService(serviceId: 'missing-service'),
      ];

      final preview = await loader.load(clientId: 'client-1', now: now);

      expect(preview, isNotNull);
      expect(
        preview!.professionalName,
        AppStrings.clientNextAppointmentProfessionalUnavailable,
      );
      expect(
        preview.servicesSummary,
        AppStrings.clientNextAppointmentSingleService,
      );
      expect(preview.operationalState, AppointmentOperationalState.current);
    });

    test('resume serviços com regra e mais N', () async {
      final startAt = now.add(const Duration(hours: 2));
      final endAt = startAt.add(const Duration(hours: 1));
      appointmentRepository.nextAppointment = _appointment(
        startAt: startAt,
        endAt: endAt,
      );
      appointmentServiceRepository.services = [
        _appointmentService(serviceId: 'service-1', displayOrder: 0),
        _appointmentService(serviceId: 'service-2', displayOrder: 1),
        _appointmentService(serviceId: 'service-3', displayOrder: 2),
      ];

      final preview = await loader.load(clientId: 'client-1', now: now);

      expect(
        preview!.servicesSummary,
        AppStrings.clientNextAppointmentServicesAndMore('Corte', 2),
      );
    });
  });
}

Appointment _appointment({
  DateTime? startAt,
  DateTime? endAt,
  String professionalId = 'professional-1',
}) {
  final start = startAt ?? DateTime(2026, 7, 14, 16);
  final end = endAt ?? start.add(const Duration(hours: 1));

  return Appointment(
    id: 'appointment-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: professionalId,
    startAt: start,
    endAt: end,
    status: AppointmentStatus.confirmed,
    isActive: true,
    createdAt: start,
    updatedAt: start,
  );
}

AppointmentService _appointmentService({
  required String serviceId,
  int displayOrder = 0,
}) {
  final now = DateTime(2026, 7, 14);
  return AppointmentService(
    id: 'line-$displayOrder',
    appointmentId: 'appointment-1',
    serviceId: serviceId,
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

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? nextAppointment;

  @override
  Future<Appointment?> findNextByClientId(
    String clientId, {
    required DateTime now,
  }) async {
    if (clientId != 'client-1') {
      return null;
    }
    return nextAppointment;
  }

  @override
  Future<List<Appointment>> findCanceledByClientId(String clientId) async {
    return const [];
  }

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
  Future<List<Appointment>> findByDay(DateTime day) async => const [];
  @override
  Future<List<Appointment>> findByDateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  }) async => const [];


  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async => const {};

  @override
  Future<Appointment> findById(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}

class _FakeAppointmentServiceRepository
    implements AppointmentServiceRepository {
  List<AppointmentService> services = const [];

  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) async {}

  @override
  Future<List<AppointmentService>> findByAppointment(String appointmentId) {
    return Future.value(services);
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
      name: 'Ana Silva',
      phone: '11999999999',
      isActive: true,
      createdAt: DateTime(2026, 7, 14),
      updatedAt: DateTime(2026, 7, 14),
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
      createdAt: DateTime(2026, 7, 14),
      updatedAt: DateTime(2026, 7, 14),
    ),
  ];

  @override
  Future<Professional> update({
    required String professionalId,
    required String name,
    String? specialties,
    String? photoPath,
    bool removePhoto = false,
  }) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeServiceRepository implements ServiceRepository {
  @override
  Future<List<Service>> findAll() async {
    final now = DateTime(2026, 7, 14);
    return [
      Service(
        id: 'service-1',
        name: 'Corte',
        durationMinutes: 60,
        price: 80,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Service(
        id: 'service-2',
        name: 'Coloração',
        durationMinutes: 90,
        price: 150,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Service(
        id: 'service-3',
        name: 'Hidratação',
        durationMinutes: 45,
        price: 70,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
