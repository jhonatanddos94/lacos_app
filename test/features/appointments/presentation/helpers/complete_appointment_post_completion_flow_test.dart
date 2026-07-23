import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_flow_result.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/application/use_cases/complete_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/presentation/dialogs/complete_appointment_dialog.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_service_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_success_sheet_host.dart';
import 'package:lacos_app/features/appointments/presentation/models/complete_appointment_success_action.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  group('Complete appointment post-completion flow', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeServiceRecordRepository serviceRecordRepository;
    late _FakeServiceRecordServiceRepository serviceRecordServiceRepository;
    late _NoopClientMemoryRepository memoryRepository;
    late CompleteAppointmentUseCase useCase;

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      serviceRecordRepository = _FakeServiceRecordRepository();
      serviceRecordServiceRepository = _FakeServiceRecordServiceRepository();
      memoryRepository = _NoopClientMemoryRepository();
      useCase = CompleteAppointmentUseCase(
        appointmentRepository: appointmentRepository,
        serviceRecordRepository: serviceRecordRepository,
        serviceRecordServiceRepository: serviceRecordServiceRepository,
        clientMemoryRepository: memoryRepository,
      );
      appointmentRepository.appointment = _appointment();
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );
    });

    Future<void> openSuccessSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            completeAppointmentUseCaseProvider.overrideWithValue(useCase),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final notifier = ProviderScope.containerOf(
                          context,
                        ).read(completeAppointmentControllerProvider.notifier);
                        notifier
                          ..reset()
                          ..setServices(
                            mapPlannedServicesToCompletedParams(_services()),
                          );

                        final serviceRecord = await showDialog<ServiceRecord>(
                          context: context,
                          builder: (context) => CompleteAppointmentDialog(
                            appointmentId: 'appointment-1',
                            clientName: 'Maria Silva',
                            services: _services(),
                          ),
                        );

                        if (!context.mounted || serviceRecord == null) {
                          return;
                        }

                        await showCompleteAppointmentSuccessBottomSheet(
                          context: context,
                        );
                      },
                      child: const Text('complete'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('complete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.appointmentCompleteConfirm));
      await tester.pumpAndSettle();
    }

    Future<CompleteAppointmentFlowResult> finishWithAction(
      WidgetTester tester,
      CompleteAppointmentSuccessAction action,
    ) async {
      CompleteAppointmentFlowResult? flowResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final successAction =
                          await showCompleteAppointmentSuccessBottomSheet(
                            context: context,
                          );

                      flowResult = CompleteAppointmentFlowResult(
                        appointment: _appointment(
                          status: AppointmentStatus.completed,
                        ),
                        successAction: successAction,
                      );
                    },
                    child: const Text('open-success'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open-success'));
      await tester.pumpAndSettle();

      final actionLabel = switch (action) {
        CompleteAppointmentSuccessAction.dismiss =>
          AppStrings.appointmentCompleteSuccessNotNow,
        CompleteAppointmentSuccessAction.addMemory =>
          AppStrings.appointmentCompleteSuccessRegisterMemory,
      };

      await tester.tap(find.text(actionLabel));
      await tester.pumpAndSettle();

      return flowResult!;
    }

    testWidgets('abre BottomSheet pós-conclusão após sucesso do dialog', (
      tester,
    ) async {
      await openSuccessSheet(tester);

      expect(appointmentRepository.completeCalls, 1);
      expect(serviceRecordRepository.createCalls, 1);
      expect(
        find.text(AppStrings.appointmentCompleteSuccessSheetTitle),
        findsOneWidget,
      );
    });

    testWidgets('atendimento permanece concluído ao fechar BottomSheet', (
      tester,
    ) async {
      await openSuccessSheet(tester);

      await tester.tap(find.text(AppStrings.appointmentCompleteSuccessNotNow));
      await tester.pumpAndSettle();

      expect(appointmentRepository.completeCalls, 1);
    });

    testWidgets('Registrar memória retorna a ação correta', (tester) async {
      final result = await finishWithAction(
        tester,
        CompleteAppointmentSuccessAction.addMemory,
      );

      expect(result.successAction, CompleteAppointmentSuccessAction.addMemory);
      expect(result.appointment.status, AppointmentStatus.completed);
    });
  });
}

List<Service> _services() {
  final now = DateTime(2026, 7, 8);

  return [
    Service(
      id: 'service-1',
      name: 'Corte',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

Appointment _appointment({
  AppointmentStatus status = AppointmentStatus.pending,
}) {
  final now = DateTime(2026, 7, 8, 10);

  return Appointment(
    id: 'appointment-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: now,
    endAt: now.add(const Duration(hours: 1)),
    status: status,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

ServiceRecord _serviceRecord() {
  final now = DateTime(2026, 7, 8, 15);

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
  var completeCalls = 0;

  @override
  Future<Appointment> complete(String appointmentId) async {
    completeCalls++;
    return completedAppointment ??
        _appointment(status: AppointmentStatus.completed);
  }

  @override
  Future<Appointment> findById(String appointmentId) async {
    return appointment ?? _appointment();
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
  @override
  Future<List<ServiceRecordService>> createMany({
    required String serviceRecordId,
    required List<ServiceRecordService> services,
  }) async {
    return const [];
  }

  @override
  Future<List<ServiceRecordService>> findByServiceRecord(
    String serviceRecordId,
  ) async {
    return const [];
  }
}

class _NoopClientMemoryRepository implements ClientMemoryRepository {
  @override
  Future<void> markMentioned(String memoryId) async {}

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

  @override
  Future<ClientMemory> archive(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> create(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String memoryId) => throw UnimplementedError();

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<ClientMemory> restore(String memoryId) => throw UnimplementedError();
}
