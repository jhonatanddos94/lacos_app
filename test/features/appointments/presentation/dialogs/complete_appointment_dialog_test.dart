import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/application/use_cases/complete_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/presentation/dialogs/complete_appointment_dialog.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_service_mapper.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  group('CompleteAppointmentDialog', () {
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

    Future<void> pumpDialog(
      WidgetTester tester, {
      Completer<void>? completeDelay,
      AppointmentStatus appointmentStatus = AppointmentStatus.pending,
    }) async {
      appointmentRepository.completeDelay = completeDelay;
      appointmentRepository.appointment = _appointment(status: appointmentStatus);
      appointmentRepository.completedAppointment = _appointment(
        status: AppointmentStatus.completed,
      );

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
                      onPressed: () {
                        final notifier = ProviderScope.containerOf(context)
                            .read(completeAppointmentControllerProvider.notifier);
                        notifier
                          ..reset()
                          ..setServices(
                            mapPlannedServicesToCompletedParams(_services()),
                          );

                        showDialog<void>(
                          context: context,
                          builder: (context) => CompleteAppointmentDialog(
                            appointmentId: 'appointment-1',
                            clientName: 'Maria Silva',
                            services: _services(),
                          ),
                        );
                      },
                      child: const Text('open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('exibe cliente e serviços', (tester) async {
      await pumpDialog(tester);

      expect(find.text(AppStrings.appointmentCompleteTitle), findsOneWidget);
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text('Corte'), findsOneWidget);
      expect(find.text('Escova'), findsOneWidget);
      expect(find.text(AppStrings.appointmentCompleteMessage), findsOneWidget);
    });

    testWidgets('confirmar chama complete com serviços copiados', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text(AppStrings.appointmentCompleteConfirm));
      await tester.pumpAndSettle();

      expect(appointmentRepository.completeCalls, 1);
      expect(serviceRecordRepository.createCalls, 1);
      expect(serviceRecordServiceRepository.createManyCalls, 1);
      expect(
        serviceRecordServiceRepository.lastCreatedServices,
        hasLength(2),
      );
      expect(
        serviceRecordServiceRepository.lastCreatedServices.first.serviceId,
        'service-1',
      );
      expect(find.byType(CompleteAppointmentDialog), findsNothing);
    });

    testWidgets('loading impede duplo clique', (tester) async {
      final completer = Completer<void>();
      await pumpDialog(tester, completeDelay: completer);

      await tester.tap(find.text(AppStrings.appointmentCompleteConfirm));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final confirmButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(confirmButton.onPressed, isNull);

      completer.complete();
      await tester.pumpAndSettle();

      expect(appointmentRepository.completeCalls, 1);
    });

    testWidgets('erro mantém dialog aberto e exibe mensagem', (tester) async {
      await pumpDialog(
        tester,
        appointmentStatus: AppointmentStatus.canceled,
      );

      await tester.tap(find.text(AppStrings.appointmentCompleteConfirm));
      await tester.pumpAndSettle();

      expect(find.byType(CompleteAppointmentDialog), findsOneWidget);
      expect(
        find.text(AppStrings.appointmentCannotComplete),
        findsOneWidget,
      );
    });

    testWidgets('cancelar fecha o dialog', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(CompleteAppointmentDialog), findsNothing);
    });
  });

  group('Appointment complete action visibility', () {
    testWidgets('botão aparece apenas para appointments concluíveis', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _CompleteActionProbe(status: AppointmentStatus.pending),
                _CompleteActionProbe(status: AppointmentStatus.completed),
              ],
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.appointmentCompleteAction), findsOneWidget);
    });
  });
}

class _CompleteActionProbe extends StatelessWidget {
  const _CompleteActionProbe({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    if (!status.canBeCompleted) {
      return const SizedBox.shrink();
    }

    return Text(AppStrings.appointmentCompleteAction);
  }
}

List<Service> _services() {
  final now = DateTime(2026, 7, 6);

  return [
    Service(
      id: 'service-1',
      name: 'Corte',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    Service(
      id: 'service-2',
      name: 'Escova',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

Appointment _appointment({
  AppointmentStatus status = AppointmentStatus.pending,
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
  var shouldFailOnCreate = false;

  @override
  Future<ServiceRecord> create(
    ServiceRecord record, {
    String? legacyPrimaryServiceId,
  }) async {
    createCalls++;
    if (shouldFailOnCreate) {
      throw const FormatException('Falha ao criar ServiceRecord.');
    }
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
  List<ServiceRecordService> lastCreatedServices = const [];

  @override
  Future<List<ServiceRecordService>> createMany({
    required String serviceRecordId,
    required List<ServiceRecordService> services,
  }) async {
    createManyCalls++;
    lastCreatedServices = services;
    return const [];
  }

  @override
  Future<List<ServiceRecordService>> findByServiceRecord(
    String serviceRecordId,
  ) async {
    return const [];
  }
}
