import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';
import 'package:lacos_app/features/appointments/application/use_cases/complete_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';

void main() {
  group('CompleteAppointmentUseCase', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeServiceRecordRepository serviceRecordRepository;
    late _FakeServiceRecordServiceRepository serviceRecordServiceRepository;
    late CompleteAppointmentUseCase useCase;

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      serviceRecordRepository = _FakeServiceRecordRepository();
      serviceRecordServiceRepository = _FakeServiceRecordServiceRepository();
      useCase = CompleteAppointmentUseCase(
        appointmentRepository: appointmentRepository,
        serviceRecordRepository: serviceRecordRepository,
        serviceRecordServiceRepository: serviceRecordServiceRepository,
      );
    });

    test('conclui appointment, cria service record e services', () async {
      appointmentRepository.appointment = _appointment();
      final completedAt = DateTime(2026, 7, 6, 15);
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
        completedAt: completedAt,
      );

      final result = await useCase(_params());

      expect(appointmentRepository.completeCalls, 1);
      expect(serviceRecordRepository.createCalls, 1);
      expect(serviceRecordServiceRepository.createManyCalls, 1);
      expect(result.id, 'service-record-1');
      expect(result.appointmentId, 'appointment-1');
      expect(result.clientId, 'client-1');
      expect(result.professionalId, 'professional-1');
      expect(result.procedureSummary, 'Corte e hidratação');
      expect(result.technicalNotes, 'Observação técnica');
      expect(result.result, 'Resultado positivo');
      expect(result.productsUsed, 'Máscara');
      expect(result.finalAmount, 180);
      expect(result.serviceDate, completedAt);
      expect(
        serviceRecordServiceRepository.lastCreatedServices,
        hasLength(2),
      );
      expect(
        serviceRecordServiceRepository.lastCreatedServices.first.serviceId,
        'service-1',
      );
      expect(serviceRecordRepository.lastLegacyPrimaryServiceId, 'service-1');
    });

    test('envia legacyPrimaryServiceId com o primeiro serviço executado', () async {
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );

      await useCase(_params());

      expect(serviceRecordRepository.lastLegacyPrimaryServiceId, 'service-1');
    });

    test('lança AppointmentNotFoundException quando appointment não existe', () async {
      appointmentRepository.appointment = null;

      await expectLater(
        useCase(_params()),
        throwsA(isA<AppointmentNotFoundException>()),
      );
      expect(appointmentRepository.completeCalls, 0);
      expect(serviceRecordRepository.createCalls, 0);
      expect(serviceRecordServiceRepository.createManyCalls, 0);
    });

    test('lança AppointmentCannotCompleteException quando status é cancelado', () async {
      appointmentRepository.appointment = _appointment(
        status: AppointmentStatus.canceled,
      );

      await expectLater(
        useCase(_params()),
        throwsA(isA<AppointmentCannotCompleteException>()),
      );
      expect(appointmentRepository.completeCalls, 0);
      expect(serviceRecordRepository.createCalls, 0);
      expect(serviceRecordServiceRepository.createManyCalls, 0);
    });

    test('appointment já completed não chama complete novamente', () async {
      appointmentRepository.appointment = _appointment(
        status: AppointmentStatus.completed,
        completedAt: DateTime(2026, 7, 6, 15),
      );

      final result = await useCase(_params());

      expect(appointmentRepository.completeCalls, 0);
      expect(serviceRecordRepository.createCalls, 1);
      expect(serviceRecordServiceRepository.createManyCalls, 1);
      expect(result.id, 'service-record-1');
    });

    test('chama appointmentRepository.complete exatamente uma vez no fluxo feliz', () async {
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );

      await useCase(_params());

      expect(appointmentRepository.completeCalls, 1);
    });

    test('retoma criação do histórico quando appointment já está completed', () async {
      appointmentRepository.appointment = _appointment(
        status: AppointmentStatus.completed,
        completedAt: DateTime(2026, 7, 6, 15),
      );
      serviceRecordRepository.existingRecord = null;

      await useCase(_params());

      expect(appointmentRepository.completeCalls, 0);
      expect(serviceRecordRepository.createCalls, 1);
    });

    test('propaga falha ao criar ServiceRecord', () async {
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );
      serviceRecordRepository.shouldFailOnCreate = true;

      await expectLater(
        useCase(_params()),
        throwsA(isA<FormatException>()),
      );
      expect(appointmentRepository.completeCalls, 1);
      expect(serviceRecordRepository.createCalls, 1);
      expect(serviceRecordServiceRepository.createManyCalls, 0);
    });

    test('não consulta serviços existentes antes de criar', () async {
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );

      await useCase(_params());

      expect(serviceRecordServiceRepository.findByServiceRecordCalls, 0);
      expect(serviceRecordServiceRepository.createManyCalls, 1);
    });

    test('propaga falha ao criar ServiceRecordService', () async {
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );
      serviceRecordServiceRepository.shouldFailOnCreateMany = true;

      await expectLater(
        useCase(_params()),
        throwsA(isA<FormatException>()),
      );
      expect(appointmentRepository.completeCalls, 1);
      expect(serviceRecordRepository.createCalls, 1);
      expect(serviceRecordServiceRepository.createManyCalls, 1);
    });
  });
}

CompleteAppointmentParams _params() {
  return const CompleteAppointmentParams(
    appointmentId: 'appointment-1',
    procedureSummary: 'Corte e hidratação',
    technicalNotes: 'Observação técnica',
    result: 'Resultado positivo',
    productsUsed: 'Máscara',
    finalAmount: 180,
    services: [
      CompletedServiceParams(
        serviceId: 'service-1',
        finalAmount: 80,
        notes: 'Corte',
      ),
      CompletedServiceParams(
        serviceId: 'service-2',
        finalAmount: 100,
        notes: 'Hidratação',
      ),
    ],
  );
}

Appointment _appointment({
  AppointmentStatus status = AppointmentStatus.pending,
  DateTime? completedAt,
}) {
  final now = DateTime(2026, 7, 6, 10);

  return Appointment(
    id: 'appointment-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: now,
    endAt: now.add(const Duration(hours: 1)),
    status: status,
    completedAt: completedAt,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;
  Appointment? completedAppointment;
  var completeCalls = 0;

  @override
  Future<Appointment> complete(String appointmentId) async {
    completeCalls++;
    return completedAppointment ?? _appointment(status: AppointmentStatus.completed);
  }

  @override
  Future<Appointment> findById(String appointmentId) async {
    final current = appointment;
    if (current == null) {
      throw StateError('Agendamento não encontrado.');
    }
    return current;
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
  Future<Appointment> create(Appointment appointment) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Appointment>> findByDay(DateTime day) {
    throw UnimplementedError();
  }

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}

class _FakeServiceRecordRepository implements ServiceRecordRepository {
  var createCalls = 0;
  var shouldFailOnCreate = false;
  ServiceRecord? existingRecord;
  String? lastLegacyPrimaryServiceId;

  @override
  Future<ServiceRecord> create(
    ServiceRecord record, {
    String? legacyPrimaryServiceId,
  }) async {
    createCalls++;
    lastLegacyPrimaryServiceId = legacyPrimaryServiceId;
    if (shouldFailOnCreate) {
      throw const FormatException('Falha ao criar ServiceRecord.');
    }

    final now = DateTime(2026, 7, 6, 15);

    return ServiceRecord(
      id: 'service-record-1',
      appointmentId: record.appointmentId,
      clientId: record.clientId,
      professionalId: record.professionalId,
      salonId: record.salonId,
      ownerId: record.ownerId,
      serviceDate: record.serviceDate,
      procedureSummary: record.procedureSummary,
      technicalNotes: record.technicalNotes,
      result: record.result,
      finalAmount: record.finalAmount,
      productsUsed: record.productsUsed,
      isActive: record.isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<ServiceRecord?> findByAppointmentId(String appointmentId) async {
    return existingRecord;
  }

  @override
  Future<List<ServiceRecord>> findByClientId(String clientId) {
    throw UnimplementedError();
  }
}

class _FakeServiceRecordServiceRepository
    implements ServiceRecordServiceRepository {
  var createManyCalls = 0;
  var findByServiceRecordCalls = 0;
  var shouldFailOnCreateMany = false;
  List<ServiceRecordService> lastCreatedServices = const [];

  @override
  Future<List<ServiceRecordService>> createMany({
    required String serviceRecordId,
    required List<ServiceRecordService> services,
  }) async {
    createManyCalls++;
    lastCreatedServices = services;
    if (shouldFailOnCreateMany) {
      throw const FormatException('Falha ao criar ServiceRecordService.');
    }

    final now = DateTime(2026, 7, 6, 15);

    return services
        .asMap()
        .entries
        .map(
          (entry) => ServiceRecordService(
            id: 'service-record-service-${entry.key + 1}',
            serviceRecordId: serviceRecordId,
            serviceId: entry.value.serviceId,
            salonId: entry.value.salonId,
            ownerId: entry.value.ownerId,
            finalAmount: entry.value.finalAmount,
            notes: entry.value.notes,
            isActive: entry.value.isActive,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ServiceRecordService>> findByServiceRecord(
    String serviceRecordId,
  ) async {
    findByServiceRecordCalls++;
    return const [];
  }
}
