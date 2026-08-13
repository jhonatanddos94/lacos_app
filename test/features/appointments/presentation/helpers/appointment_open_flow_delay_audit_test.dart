import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_operational_state_resolver.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_preparation_eligibility.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_details_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/appointments/presentation/models/appointment_preparation_action.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

import '../../helpers/gated_client_memory_repository.dart';

void main() {
  const resolver = AppointmentOperationalStateResolver();

  setUp(resetAgendaAppointmentOpenGuardForTest);
  tearDown(resetAgendaAppointmentOpenGuardForTest);

  final now = DateTime(2026, 8, 13, 10, 30);
  final currentAppointment = AgendaAppointmentDisplay(
    appointmentId: 'appointment-current',
    clientId: 'client-1',
    clientName: 'Cliente',
    servicesSummary: 'Corte',
    startAt: DateTime(2026, 8, 13, 10),
    endAt: DateTime(2026, 8, 13, 11),
    status: AppointmentStatus.confirmed,
  );

  final displayedMemories = [
    gatedMemory(id: 'm1', content: 'Memória um'),
    gatedMemory(id: 'm2', content: 'Memória dois'),
    gatedMemory(id: 'm3', content: 'Memória três'),
  ];

  test('current é elegível para preparation', () {
    expect(
      resolver
          .resolve(
            status: currentAppointment.status,
            startAt: currentAppointment.startAt,
            endAt: currentAppointment.endAt,
            now: now,
          )
          .name,
      'current',
    );
    expect(
      AppointmentPreparationEligibility.isEligible(
        status: currentAppointment.status,
        startAt: currentAppointment.startAt,
        endAt: currentAppointment.endAt,
        now: now,
      ),
      isTrue,
    );
  });

  testWidgets('sheet abre com memories Future pendente', (tester) async {
    final repository = GatedClientMemoryRepository(
      findCompleter: Completer<List<ClientMemory>>(),
      memories: displayedMemories,
    );

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
    expect(find.text(AppStrings.appointmentPreparationTitle), findsOneWidget);
    expect(find.text('Cliente'), findsWidgets);
    expect(find.textContaining('Corte', findRichText: true), findsWidgets);
    expect(
      find.byKey(AppointmentPreparationBottomSheet.memoriesLoadingKey),
      findsOneWidget,
    );
    expect(find.text('Memória um'), findsNothing);
    expect(repository.touchCalls, 0);
  });

  testWidgets('memórias aparecem depois e só então dispara touch', (
    tester,
  ) async {
    final findCompleter = Completer<List<ClientMemory>>();
    final repository = GatedClientMemoryRepository(
      findCompleter: findCompleter,
      memories: displayedMemories,
    );

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.touchCalls, 0);

    findCompleter.complete(displayedMemories);
    await tester.pump();
    await tester.pump();

    expect(find.text('Memória um'), findsOneWidget);
    expect(find.text('Memória dois'), findsOneWidget);
    expect(find.text('Memória três'), findsOneWidget);
    expect(repository.touchCalls, 1);
    expect(repository.lastTouchedIds, ['m1', 'm2', 'm3']);
    expect(repository.findByClientCalls, 1);
  });

  testWidgets('lista vazia não dispara touch e mostra empty', (tester) async {
    final findCompleter = Completer<List<ClientMemory>>();
    final repository = GatedClientMemoryRepository(
      findCompleter: findCompleter,
    );

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    findCompleter.complete(const []);
    await tester.pump();
    await tester.pump();

    expect(
      find.text(AppStrings.appointmentPreparationMemoriesEmpty),
      findsOneWidget,
    );
    expect(repository.touchCalls, 0);
  });

  testWidgets('touch pendente não bloqueia continuar nem fechar', (
    tester,
  ) async {
    final findCompleter = Completer<List<ClientMemory>>();
    final touchCompleter = Completer<void>();
    final repository = GatedClientMemoryRepository(
      findCompleter: findCompleter,
      touchCompleter: touchCompleter,
      memories: displayedMemories,
    );

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    findCompleter.complete(displayedMemories);
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
    expect(repository.touchCalls, 1);

    await _popPreparation(
      tester,
      AppointmentPreparationAction.continueToAppointment,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
    expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
    expect(touchCompleter.isCompleted, isFalse);
  });

  testWidgets('exception no touch não quebra o fluxo', (tester) async {
    final findCompleter = Completer<List<ClientMemory>>();
    final repository = GatedClientMemoryRepository(
      findCompleter: findCompleter,
      memories: displayedMemories,
      touchError: Exception('touch failed'),
    );

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    findCompleter.complete(displayedMemories);
    await tester.pump();
    await tester.pump();

    expect(find.text('Memória um'), findsOneWidget);

    await _popPreparation(
      tester,
      AppointmentPreparationAction.continueToAppointment,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
  });

  testWidgets('erro das memórias não impede continuar', (tester) async {
    final findCompleter = Completer<List<ClientMemory>>();
    final repository = GatedClientMemoryRepository(
      findCompleter: findCompleter,
    );

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    findCompleter.completeError(Exception('memories failed'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Cliente'), findsWidgets);
    expect(find.textContaining('Corte', findRichText: true), findsWidgets);
    expect(
      find.byKey(AppointmentPreparationBottomSheet.memoriesErrorKey),
      findsOneWidget,
    );
    expect(find.text(AppStrings.clientMemoriesLoadError), findsOneWidget);
    expect(repository.touchCalls, 0);

    await _popPreparation(
      tester,
      AppointmentPreparationAction.continueToAppointment,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
  });

  testWidgets('fechar durante loading é seguro e não dispara touch', (
    tester,
  ) async {
    final findCompleter = Completer<List<ClientMemory>>();
    final repository = GatedClientMemoryRepository(
      findCompleter: findCompleter,
      memories: displayedMemories,
    );

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await _popPreparation(tester, AppointmentPreparationAction.dismiss);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
    expect(find.byType(AppointmentDetailsBottomSheet), findsNothing);

    findCompleter.complete(displayedMemories);
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppointmentDetailsBottomSheet), findsNothing);
    expect(repository.touchCalls, 0);
  });

  testWidgets('continuar durante loading abre details sem touch', (
    tester,
  ) async {
    final findCompleter = Completer<List<ClientMemory>>();
    final repository = GatedClientMemoryRepository(
      findCompleter: findCompleter,
      memories: displayedMemories,
    );

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await _popPreparation(
      tester,
      AppointmentPreparationAction.continueToAppointment,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);

    findCompleter.complete(displayedMemories);
    await tester.pump();
    await tester.pump();

    expect(repository.touchCalls, 0);
  });

  testWidgets(
    'segunda abertura continua imediata e não refetcha por invalidate',
    (tester) async {
      final repository = GatedClientMemoryRepository(
        memories: displayedMemories,
      );

      await _pumpOpenButton(
        tester,
        repository: repository,
        appointment: currentAppointment,
        now: now,
      );

      await tester.tap(find.text('open-flow'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
      expect(repository.findByClientCalls, 1);

      await _popPreparation(tester, AppointmentPreparationAction.dismiss);
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-flow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
      expect(find.text('Memória um'), findsOneWidget);
      expect(repository.findByClientCalls, 1);
    },
  );

  testWidgets('touch não provoca refetch imediato das memórias', (
    tester,
  ) async {
    final repository = GatedClientMemoryRepository(memories: displayedMemories);

    await _pumpOpenButton(
      tester,
      repository: repository,
      appointment: currentAppointment,
      now: now,
    );

    await tester.tap(find.text('open-flow'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Memória um'), findsOneWidget);
    expect(repository.touchCalls, 1);
    expect(repository.findByClientCalls, 1);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.findByClientCalls, 1);
    expect(find.text('Memória um'), findsOneWidget);
  });
}

Future<void> _pumpOpenButton(
  WidgetTester tester, {
  required GatedClientMemoryRepository repository,
  required AgendaAppointmentDisplay appointment,
  required DateTime now,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [clientMemoryRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    openAgendaAppointmentFlow(
                      context: context,
                      appointment: appointment,
                      now: now,
                    );
                  },
                  child: const Text('open-flow'),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

Future<void> _popPreparation(
  WidgetTester tester,
  AppointmentPreparationAction action,
) async {
  Navigator.of(
    tester.element(find.byType(AppointmentPreparationBottomSheet)),
  ).pop(action);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
