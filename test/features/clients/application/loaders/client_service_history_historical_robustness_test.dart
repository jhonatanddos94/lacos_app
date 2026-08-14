import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/clients/application/loaders/client_service_history_loader.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';

void main() {
  group('ClientServiceHistoryLoader historical robustness', () {
    late _FakeServiceRecordRepository serviceRecordRepository;
    late _FakeServiceRecordServiceRepository serviceRecordServiceRepository;
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeAppointmentServiceRepository appointmentServiceRepository;
    late _FakeServiceRepository serviceRepository;
    late ClientServiceHistoryLoader loader;

    setUp(() {
      serviceRecordRepository = _FakeServiceRecordRepository();
      serviceRecordServiceRepository = _FakeServiceRecordServiceRepository();
      appointmentRepository = _FakeAppointmentRepository();
      appointmentServiceRepository = _FakeAppointmentServiceRepository();
      serviceRepository = _FakeServiceRepository();
      loader = ClientServiceHistoryLoader(
        serviceRecordRepository: serviceRecordRepository,
        serviceRecordServiceRepository: serviceRecordServiceRepository,
        appointmentRepository: appointmentRepository,
        appointmentServiceRepository: appointmentServiceRepository,
        professionalRepository: _FakeProfessionalRepository(),
        serviceRepository: serviceRepository,
      );
    });

    test('serviço renomeado não altera histórico com procedureSummary', () async {
      serviceRecordRepository.records = [
        _record(
          id: 'sr-1',
          procedureSummary: 'Corte feminino',
          finalAmount: 80,
        ),
      ];
      serviceRepository.services = [
        _service(id: 'service-1', name: 'Corte premium', price: 120),
      ];

      final items = await loader.load(clientId: 'client-1');

      expect(items.single.servicesSummary, 'Corte feminino');
      expect(items.single.totalAmount, 80);
    });

    test('preço atual do catálogo não altera finalAmount snapshot', () async {
      serviceRecordRepository.records = [
        _record(id: 'sr-1', procedureSummary: 'Corte', finalAmount: 80),
      ];
      serviceRepository.services = [
        _service(id: 'service-1', name: 'Corte', price: 999),
      ];

      final items = await loader.load(clientId: 'client-1');
      expect(items.single.totalAmount, 80);
    });

    test('serviço ausente no catálogo ainda renderiza com snapshot', () async {
      serviceRecordRepository.records = [
        _record(
          id: 'sr-1',
          procedureSummary: 'Corte feminino + Hidratação',
          finalAmount: 180,
        ),
      ];
      serviceRepository.services = const [];

      final items = await loader.load(clientId: 'client-1');

      expect(items.single.servicesSummary, 'Corte feminino + Hidratação');
      expect(items.single.totalAmount, 180);
    });

    test('legado sem snapshot usa fallback amigável', () async {
      serviceRecordRepository.records = [
        _record(id: 'sr-1', procedureSummary: null, finalAmount: null),
      ];
      serviceRecordServiceRepository.lines = [
        _line(id: 'l1', serviceRecordId: 'sr-1', serviceId: 'missing'),
      ];
      serviceRepository.services = const [];

      final items = await loader.load(clientId: 'client-1');

      expect(
        items.single.servicesSummary,
        AppStrings.clientNextAppointmentSingleService,
      );
      expect(items.single.totalAmount, isNull);
    });

    test(
      'RISCO documentado: cancelado ainda depende do nome atual do catálogo',
      () async {
        appointmentRepository.canceled = [
          _canceled(id: 'appt-1', startAt: DateTime(2026, 7, 20)),
        ];
        appointmentServiceRepository.lines = [
          AppointmentService(
            id: 'as-1',
            appointmentId: 'appt-1',
            serviceId: 'service-1',
            salonId: 'salon-1',
            ownerId: 'owner-1',
            priceAtBooking: 80,
            durationMinutesAtBooking: 60,
            displayOrder: 0,
            isActive: true,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ];
        serviceRepository.services = [
          _service(id: 'service-1', name: 'Corte premium', price: 120),
        ];

        final items = await loader.load(clientId: 'client-1');

        expect(items.single.kind, ClientServiceHistoryKind.canceled);
        expect(items.single.servicesSummary, 'Corte premium');
        expect(items.single.totalAmount, isNull);
      },
    );
  });
}

ServiceRecord _record({
  required String id,
  String? procedureSummary,
  double? finalAmount,
}) {
  final stamp = DateTime(2026, 7, 1);
  return ServiceRecord(
    id: id,
    appointmentId: 'appointment-$id',
    clientId: 'client-1',
    professionalId: 'professional-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    serviceDate: stamp,
    procedureSummary: procedureSummary,
    finalAmount: finalAmount,
    isActive: true,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

ServiceRecordService _line({
  required String id,
  required String serviceRecordId,
  required String serviceId,
}) {
  final stamp = DateTime(2026, 1, 1);
  return ServiceRecordService(
    id: id,
    serviceRecordId: serviceRecordId,
    serviceId: serviceId,
    salonId: 'salon-1',
    ownerId: 'owner-1',
    isActive: true,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

Service _service({
  required String id,
  required String name,
  required double price,
}) {
  final stamp = DateTime(2026, 1, 1);
  return Service(
    id: id,
    name: name,
    durationMinutes: 60,
    price: price,
    isActive: true,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

Appointment _canceled({required String id, required DateTime startAt}) {
  final stamp = DateTime(2026, 1, 1);
  return Appointment(
    id: id,
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1)),
    status: AppointmentStatus.canceled,
    canceledAt: stamp,
    canceledBy: AppointmentCanceledBy.client,
    isActive: true,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

class _FakeServiceRecordRepository implements ServiceRecordRepository {
  List<ServiceRecord> records = const [];

  @override
  Future<List<ServiceRecord>> findByClientId(String clientId) async => records;

  @override
  Future<ServiceRecord?> findByAppointmentId(String appointmentId) async => null;

  @override
  Future<ServiceRecord> create(
    ServiceRecord record, {
    String? legacyPrimaryServiceId,
  }) => throw UnimplementedError();
}

class _FakeServiceRecordServiceRepository
    implements ServiceRecordServiceRepository {
  List<ServiceRecordService> lines = const [];

  @override
  Future<List<ServiceRecordService>> findByServiceRecord(
    String serviceRecordId,
  ) async => lines;

  @override
  Future<List<ServiceRecordService>> findByServiceRecordIds(
    List<String> serviceRecordIds,
  ) async {
    final ids = serviceRecordIds.toSet();
    return lines
        .where((line) => ids.contains(line.serviceRecordId))
        .toList(growable: false);
  }

  @override
  Future<List<ServiceRecordService>> createMany({
    required String serviceRecordId,
    required List<ServiceRecordService> services,
  }) => throw UnimplementedError();
}

class _FakeAppointmentRepository implements AppointmentRepository {
  List<Appointment> canceled = const [];

  @override
  Future<List<Appointment>> findCanceledByClientId(String clientId) async =>
      canceled;

  @override
  Future<Appointment?> findNextByClientId(
    String clientId, {
    required DateTime now,
  }) async => null;

  @override
  Future<Appointment> cancel({
    required String appointmentId,
    required AppointmentCanceledBy canceledBy,
    String? cancellationReason,
  }) => throw UnimplementedError();

  @override
  Future<Appointment> complete(String appointmentId) =>
      throw UnimplementedError();

  @override
  Future<Appointment> create(Appointment appointment) =>
      throw UnimplementedError();

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
  Future<Appointment> findById(String appointmentId) =>
      throw UnimplementedError();

  @override
  Future<Appointment> update(Appointment appointment) =>
      throw UnimplementedError();
}

class _FakeAppointmentServiceRepository
    implements AppointmentServiceRepository {
  List<AppointmentService> lines = const [];

  @override
  Future<List<AppointmentService>> findByAppointment(
    String appointmentId,
  ) async => lines;

  @override
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) async {
    final ids = appointmentIds.toSet();
    return lines
        .where((line) => ids.contains(line.appointmentId))
        .toList(growable: false);
  }

  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteByAppointment(String appointmentId) async {}
}

class _FakeProfessionalRepository implements ProfessionalRepository {
  @override
  Future<List<Professional>> findAll() async {
    final stamp = DateTime(2026, 1, 1);
    return [
      Professional(
        id: 'professional-1',
        name: 'Ana',
        isActive: true,
        createdAt: stamp,
        updatedAt: stamp,
      ),
    ];
  }

  @override
  Future<Professional?> getCurrentProfessional() async => null;

  @override
  Future<Professional> create({
    required String name,
    String? specialties,
  }) => throw UnimplementedError();

  @override
  Future<Professional> update({
    required String professionalId,
    required String name,
    String? specialties,
    String? photoPath,
    bool removePhoto = false,
  }) => throw UnimplementedError();
}

class _FakeServiceRepository implements ServiceRepository {
  List<Service> services = const [];

  @override
  Future<List<Service>> findAll() async => services;

  @override
  Future<Service> create({
    required String name,
    required int durationMinutes,
    String? category,
    double? price,
    String? description,
  }) => throw UnimplementedError();

  @override
  Future<Service> update(Service service) => throw UnimplementedError();

  @override
  Future<void> delete(String serviceId) => throw UnimplementedError();
}
