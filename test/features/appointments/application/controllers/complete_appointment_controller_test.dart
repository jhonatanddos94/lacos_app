import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/appointments/application/controllers/complete_appointment_controller.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_params.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_state.dart';
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
  group('CompleteAppointmentController', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeServiceRecordRepository serviceRecordRepository;
    late _FakeServiceRecordServiceRepository serviceRecordServiceRepository;
    late CompleteAppointmentUseCase useCase;
    late CompleteAppointmentController controller;

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      serviceRecordRepository = _FakeServiceRecordRepository();
      serviceRecordServiceRepository = _FakeServiceRecordServiceRepository();
      useCase = CompleteAppointmentUseCase(
        appointmentRepository: appointmentRepository,
        serviceRecordRepository: serviceRecordRepository,
        serviceRecordServiceRepository: serviceRecordServiceRepository,
      );
      controller = CompleteAppointmentController(useCase);
    });

    test('inicia com estado vazio', () {
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.success, isFalse);
      expect(controller.state.procedureSummary, isEmpty);
      expect(controller.state.technicalNotes, isEmpty);
      expect(controller.state.result, isEmpty);
      expect(controller.state.productsUsed, isEmpty);
      expect(controller.state.finalAmount, isNull);
      expect(controller.state.services, isEmpty);
    });

    test('atualiza campos do formulário', () {
      controller
        ..setProcedureSummary('Corte')
        ..setTechnicalNotes('Observação técnica')
        ..setResult('Resultado positivo')
        ..setProductsUsed('Máscara')
        ..setFinalAmount(180)
        ..setServices(const [
          CompletedServiceParams(serviceId: 'service-1', finalAmount: 80),
        ]);

      expect(controller.state.procedureSummary, 'Corte');
      expect(controller.state.technicalNotes, 'Observação técnica');
      expect(controller.state.result, 'Resultado positivo');
      expect(controller.state.productsUsed, 'Máscara');
      expect(controller.state.finalAmount, 180);
      expect(controller.state.services, hasLength(1));
    });

    test('define erro quando tenta concluir sem serviços', () async {
      final result = await controller.complete('appointment-1');

      expect(result, isNull);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.success, isFalse);
      expect(
        controller.state.errorMessage,
        AppStrings.appointmentCompleteAtLeastOneService,
      );
      expect(appointmentRepository.completeCalls, 0);
    });

    test('define erro quando appointmentId está vazio', () async {
      controller.setServices(const [
        CompletedServiceParams(serviceId: 'service-1'),
      ]);

      final result = await controller.complete('   ');

      expect(result, isNull);
      expect(
        controller.state.errorMessage,
        AppValidationMessages.requiredField,
      );
      expect(appointmentRepository.completeCalls, 0);
    });

    test('conclui com sucesso', () async {
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
        completedAt: DateTime(2026, 7, 6, 15),
      );
      controller
        ..setProcedureSummary('Corte')
        ..setTechnicalNotes('Notas')
        ..setResult('Bom resultado')
        ..setProductsUsed('Shampoo')
        ..setFinalAmount(120)
        ..setServices(const [
          CompletedServiceParams(
            serviceId: 'service-1',
            finalAmount: 120,
            notes: 'Corte',
          ),
        ]);

      final result = await controller.complete('appointment-1');

      expect(result, isNotNull);
      expect(result!.id, 'service-record-1');
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.success, isTrue);
      expect(controller.state.errorMessage, isNull);
      expect(appointmentRepository.completeCalls, 1);
      expect(serviceRecordRepository.createCalls, 1);
      expect(serviceRecordServiceRepository.createManyCalls, 1);
    });

    test('ignora segunda chamada enquanto submission está em andamento', () async {
      final completer = Completer<void>();
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completeDelay = completer;
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );
      controller.setServices(const [
        CompletedServiceParams(serviceId: 'service-1'),
      ]);

      final firstCall = controller.complete('appointment-1');
      final secondCall = controller.complete('appointment-1');

      expect(controller.state.isLoading, isTrue);

      completer.complete();
      await firstCall;
      final secondResult = await secondCall;

      expect(secondResult, isNull);
      expect(appointmentRepository.completeCalls, 1);
    });

    test('mantém loading durante submit', () async {
      final completer = Completer<void>();
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completeDelay = completer;
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );
      controller.setServices(const [
        CompletedServiceParams(serviceId: 'service-1'),
      ]);

      final submitFuture = controller.complete('appointment-1');

      expect(controller.state.isLoading, isTrue);
      expect(controller.state.success, isFalse);

      completer.complete();
      await submitFuture;

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.success, isTrue);
    });

    test('mapeia AppointmentCannotCompleteException', () async {
      appointmentRepository.appointment = _appointment(
        status: AppointmentStatus.canceled,
      );
      controller.setServices(const [
        CompletedServiceParams(serviceId: 'service-1'),
      ]);

      final result = await controller.complete('appointment-1');

      expect(result, isNull);
      expect(controller.state.success, isFalse);
      expect(
        controller.state.errorMessage,
        AppStrings.appointmentCannotComplete,
      );
      expect(appointmentRepository.completeCalls, 0);
    });

    test('reset limpa estado', () async {
      controller
        ..setProcedureSummary('Corte')
        ..setTechnicalNotes('Notas')
        ..setResult('Resultado')
        ..setProductsUsed('Produto')
        ..setFinalAmount(90)
        ..setServices(const [
          CompletedServiceParams(serviceId: 'service-1'),
        ]);

      controller.reset();

      expect(controller.state, const CompleteAppointmentState());
    });
  });
}

// Reuse minimal fakes from use case tests pattern.

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

ServiceRecord _serviceRecord() {
  final now = DateTime(2026, 7, 6, 15);

  return ServiceRecord(
    id: 'service-record-1',
    appointmentId: 'appointment-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;
  Appointment? completedAppointment;
  Completer<void>? completeDelay;
  var completeCalls = 0;

  @override
  Future<Appointment> complete(String appointmentId) async {
    completeCalls++;
    if (completeDelay != null) {
      await completeDelay!.future;
    }
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

  @override
  Future<ServiceRecord> create(
    ServiceRecord record, {
    String? legacyPrimaryServiceId,
  }) async {
    createCalls++;
    return _serviceRecord();
  }

  @override
  Future<ServiceRecord?> findByAppointmentId(String appointmentId) async {
    return null;
  }

  @override
  Future<List<ServiceRecord>> findByClientId(String clientId) {
    throw UnimplementedError();
  }
}

class _FakeServiceRecordServiceRepository
    implements ServiceRecordServiceRepository {
  var createManyCalls = 0;

  @override
  Future<List<ServiceRecordService>> createMany({
    required String serviceRecordId,
    required List<ServiceRecordService> services,
  }) async {
    createManyCalls++;
    return const [];
  }

  @override
  Future<List<ServiceRecordService>> findByServiceRecord(
    String serviceRecordId,
  ) async {
    return const [];
  }
}
