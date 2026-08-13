import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/presentation/pages/agenda_page.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

import '../../../../helpers/home_test_fixtures.dart';
import '../../../appointments/helpers/gated_client_memory_repository.dart';

void main() {
  setUp(resetAgendaAppointmentOpenGuardForTest);
  tearDown(resetAgendaAppointmentOpenGuardForTest);

  testWidgets('current abre preparação imediatamente com memórias pendentes', (
    tester,
  ) async {
    final now = DateTime(2026, 8, 13, 14);
    final repository = GatedClientMemoryRepository(
      findCompleter: Completer<List<ClientMemory>>(),
    );

    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => [
              homeTestAppointment(
                id: 'current',
                clientName: 'Josefa',
                startAt: DateTime(2026, 8, 13, 13, 30),
              ),
            ],
          ),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => {DateTime(2026, 8, 13)},
          ),
          clientMemoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AgendaPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Josefa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
    expect(
      find.byKey(AppointmentPreparationBottomSheet.memoriesLoadingKey),
      findsOneWidget,
    );
    expect(repository.findByClientCalls, 1);
    expect(repository.touchCalls, 0);
  });
}
