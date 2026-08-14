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
  group('ClientServiceHistoryLoader', () {
    late _FakeServiceRecordRepository serviceRecordRepository;
    late _FakeServiceRecordServiceRepository serviceRecordServiceRepository;
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeAppointmentServiceRepository appointmentServiceRepository;
    late ClientServiceHistoryLoader loader;

    setUp(() {
      serviceRecordRepository = _FakeServiceRecordRepository();
      serviceRecordServiceRepository = _FakeServiceRecordServiceRepository();
      appointmentRepository = _FakeAppointmentRepository();
      appointmentServiceRepository = _FakeAppointmentServiceRepository();
      loader = ClientServiceHistoryLoader(
        serviceRecordRepository: serviceRecordRepository,
        serviceRecordServiceRepository: serviceRecordServiceRepository,
        appointmentRepository: appointmentRepository,
        appointmentServiceRepository: appointmentServiceRepository,
        professionalRepository: _FakeProfessionalRepository(),
        serviceRepository: _FakeServiceRepository(),
      );
    });

    test('retorna vazio sem clientId', () async {
      expect(await loader.load(clientId: '  '), isEmpty);
      expect(serviceRecordRepository.findByClientIdCalls, 0);
      expect(appointmentRepository.findCanceledCalls, 0);
    });

    test('somente completed', () async {
      serviceRecordRepository.records = [
        _record(
          id: 'sr-1',
          serviceDate: DateTime(2026, 7, 27),
          finalAmount: 120,
          procedureSummary: 'Corte',
        ),
      ];

      final items = await loader.load(clientId: 'client-1');

      expect(items, hasLength(1));
      expect(items.single.kind, ClientServiceHistoryKind.completed);
      expect(items.single.totalAmount, 120);
      expect(appointmentServiceRepository.findByAppointmentsCalls, 0);
    });

    test('somente canceled', () async {
      appointmentRepository.canceled = [
        _canceled(
          id: 'appt-1',
          startAt: DateTime(2026, 7, 20, 10),
          canceledBy: AppointmentCanceledBy.client,
          reason: 'Imprevisto',
        ),
      ];
      appointmentServiceRepository.lines = [
        _appointmentService(
          id: 'as-1',
          appointmentId: 'appt-1',
          serviceId: 'service-1',
        ),
      ];

      final items = await loader.load(clientId: 'client-1');

      expect(items, hasLength(1));
      expect(items.single.kind, ClientServiceHistoryKind.canceled);
      expect(items.single.occurredAt, DateTime(2026, 7, 20, 10));
      expect(items.single.totalAmount, isNull);
      expect(items.single.servicesSummary, 'Corte');
      expect(items.single.cancellationReasonPreview, 'Imprevisto');
      expect(items.single.professionalName, 'Ana');
    });

    test('mistura ordena cronologicamente e não duplica completed', () async {
      serviceRecordRepository.records = [
        _record(
          id: 'sr-1',
          appointmentId: 'appt-completed',
          serviceDate: DateTime(2026, 7, 27),
          finalAmount: 120,
          procedureSummary: 'Hidratação',
        ),
        _record(
          id: 'sr-2',
          serviceDate: DateTime(2026, 7, 5),
          finalAmount: 80,
          procedureSummary: 'Corte',
        ),
      ];
      appointmentRepository.canceled = [
        _canceled(id: 'appt-canceled', startAt: DateTime(2026, 7, 20, 14)),
      ];

      final items = await loader.load(clientId: 'client-1');

      expect(items.map((item) => item.uniqueId), [
        'sr:sr-1',
        'appt:appt-canceled',
        'sr:sr-2',
      ]);
      expect(
        items.where((item) => item.kind == ClientServiceHistoryKind.completed),
        hasLength(2),
      );
      expect(
        items.where((item) => item.kind == ClientServiceHistoryKind.canceled),
        hasLength(1),
      );
    });

    test('motivo ausente usa canceledBy ou Motivo não informado', () async {
      appointmentRepository.canceled = [
        _canceled(
          id: 'a1',
          startAt: DateTime(2026, 6, 1),
          canceledBy: AppointmentCanceledBy.salon,
        ),
        _canceled(id: 'a2', startAt: DateTime(2026, 5, 1)),
      ];

      final items = await loader.load(clientId: 'client-1');

      expect(
        items.first.cancellationReasonPreview,
        AppStrings.appointmentCanceledBySalonLabel,
      );
      expect(
        items.last.cancellationReasonPreview,
        AppStrings.appointmentCancellationReasonNotProvided,
      );
    });

    test('não usa preço atual do catálogo para total completed', () async {
      serviceRecordRepository.records = [
        _record(
          id: 'sr-1',
          serviceDate: DateTime(2026, 7, 1),
          finalAmount: 50,
          procedureSummary: 'Corte',
        ),
      ];

      final items = await loader.load(clientId: 'client-1');
      expect(items.single.totalAmount, 50);
    });
  });
}

ServiceRecord _record({
  required String id,
  required DateTime? serviceDate,
  double? finalAmount,
  String? procedureSummary,
  String? appointmentId,
  DateTime? createdAt,
}) {
  final stamp = createdAt ?? DateTime(2026, 1, 1);
  return ServiceRecord(
    id: id,
    appointmentId: appointmentId ?? 'appointment-$id',
    clientId: 'client-1',
    professionalId: 'professional-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    serviceDate: serviceDate,
    procedureSummary: procedureSummary,
    finalAmount: finalAmount,
    isActive: true,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

Appointment _canceled({
  required String id,
  required DateTime startAt,
  AppointmentCanceledBy? canceledBy,
  String? reason,
}) {
  return _appointment(
    id: id,
    status: AppointmentStatus.canceled,
    startAt: startAt,
    canceledBy: canceledBy,
    reason: reason,
  );
}

Appointment _appointment({
  required String id,
  required AppointmentStatus status,
  required DateTime startAt,
  AppointmentCanceledBy? canceledBy,
  String? reason,
}) {
  final stamp = DateTime(2026, 1, 1);
  return Appointment(
    id: id,
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1)),
    status: status,
    canceledAt: status == AppointmentStatus.canceled ? stamp : null,
    canceledBy: canceledBy,
    cancellationReason: reason,
    isActive: true,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

AppointmentService _appointmentService({
  required String id,
  required String appointmentId,
  required String serviceId,
}) {
  final stamp = DateTime(2026, 1, 1);
  return AppointmentService(
    id: id,
    appointmentId: appointmentId,
    serviceId: serviceId,
    salonId: 'salon-1',
    ownerId: 'owner-1',
    durationMinutesAtBooking: 60,
    displayOrder: 0,
    isActive: true,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

class _FakeServiceRecordRepository implements ServiceRecordRepository {
  List<ServiceRecord> records = const [];
  var findByClientIdCalls = 0;

  @override
  Future<List<ServiceRecord>> findByClientId(String clientId) async {
    findByClientIdCalls++;
    return records;
  }

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
  var findCanceledCalls = 0;

  @override
  Future<List<Appointment>> findCanceledByClientId(String clientId) async {
    findCanceledCalls++;
    return canceled;
  }

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
  var findByAppointmentsCalls = 0;

  @override
  Future<List<AppointmentService>> findByAppointment(
    String appointmentId,
  ) async {
    return lines
        .where((line) => line.appointmentId == appointmentId)
        .toList(growable: false);
  }

  @override
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) async {
    findByAppointmentsCalls++;
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
  Future<void> deleteByAppointment(String appointmentId) =>
      throw UnimplementedError();
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
  @override
  Future<List<Service>> findAll() async {
    final stamp = DateTime(2026, 1, 1);
    return [
      Service(
        id: 'service-1',
        name: 'Corte',
        durationMinutes: 60,
        price: 999,
        isActive: true,
        createdAt: stamp,
        updatedAt: stamp,
      ),
      Service(
        id: 'service-2',
        name: 'Coloração',
        durationMinutes: 90,
        price: 888,
        isActive: true,
        createdAt: stamp,
        updatedAt: stamp,
      ),
    ];
  }

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
