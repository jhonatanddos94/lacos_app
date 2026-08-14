import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/agenda/presentation/pages/agenda_page.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_chip.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_details_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

import '../../../../helpers/home_test_fixtures.dart';
import '../../../appointments/helpers/gated_client_memory_repository.dart';

void main() {
  setUp(resetAgendaAppointmentOpenGuardForTest);
  tearDown(resetAgendaAppointmentOpenGuardForTest);

  /// Frozen local "now". Never DateTime.now() — wall clock must not decide
  /// preparation eligibility in this suite.
  final frozenNow = DateTime(2026, 8, 13, 15);

  AgendaAppointmentDisplay currentAppointment({
    AppointmentStatus status = AppointmentStatus.pending,
    String clientName = 'Josefa',
    DateTime? startAt,
    Duration duration = const Duration(hours: 1),
  }) {
    return homeTestAppointment(
      id: 'current',
      clientName: clientName,
      startAt: startAt ?? DateTime(2026, 8, 13, 14, 30),
      duration: duration,
      status: status,
    );
  }

  Future<void> pumpAgenda(
    WidgetTester tester, {
    required AgendaAppointmentDisplay appointment,
    required GatedClientMemoryRepository repository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(frozenNow)),
          calendarTodayProvider.overrideWithValue(AgendaDay.from(frozenNow)),
          agendaAppointmentsDisplayProvider.overrideWith((ref, day) async {
            if (day == AgendaDay.from(appointment.startAt)) {
              return [appointment];
            }
            return const <AgendaAppointmentDisplay>[];
          }),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => {normalizeAppointmentDate(appointment.startAt)},
          ),
          clientMemoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AgendaPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapClient(WidgetTester tester, String clientName) async {
    await tester.tap(find.text(clientName));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> selectDay(WidgetTester tester, DateTime day) async {
    final normalizedDay = normalizeAppointmentDate(day);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AgendaDayChip &&
            normalizeAppointmentDate(widget.day) == normalizedDay,
      ),
    );
    await tester.pumpAndSettle();
  }

  GatedClientMemoryRepository pendingMemoriesRepository() {
    return GatedClientMemoryRepository(
      findCompleter: Completer<List<ClientMemory>>(),
    );
  }

  GatedClientMemoryRepository idleMemoriesRepository() {
    return GatedClientMemoryRepository();
  }

  testWidgets(
    '4/current: 14:30–15:30 com agora=15:00 abre preparação imediatamente',
    (tester) async {
      final repository = pendingMemoriesRepository();
      final appointment = currentAppointment();

      await pumpAgenda(
        tester,
        appointment: appointment,
        repository: repository,
      );
      await tapClient(tester, 'Josefa');

      expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
      expect(
        find.byKey(AppointmentPreparationBottomSheet.memoriesLoadingKey),
        findsOneWidget,
      );
      expect(find.byType(AppointmentDetailsBottomSheet), findsNothing);
      expect(repository.findByClientCalls, 1);
      expect(repository.touchCalls, 0);
    },
  );

  testWidgets(
    '1: mesmo horário no dia anterior não é elegível',
    (tester) async {
      final appointment = currentAppointment(
        clientName: 'Helena',
        startAt: DateTime(2026, 8, 12, 14, 30),
      );

      await pumpAgenda(
        tester,
        appointment: appointment,
        repository: idleMemoriesRepository(),
      );
      await selectDay(tester, DateTime(2026, 8, 12));
      await tapClient(tester, 'Helena');

      expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
      expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
    },
  );

  testWidgets(
    '2: futuro fora da janela de 30 min não é elegível',
    (tester) async {
      final appointment = currentAppointment(
        clientName: 'Carla',
        startAt: DateTime(2026, 8, 13, 16),
      );

      await pumpAgenda(
        tester,
        appointment: appointment,
        repository: idleMemoriesRepository(),
      );
      await tapClient(tester, 'Carla');

      expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
      expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
    },
  );

  testWidgets(
    '3: dentro da janela de 30 min é elegível',
    (tester) async {
      final repository = pendingMemoriesRepository();
      final appointment = currentAppointment(
        clientName: 'Ana',
        startAt: DateTime(2026, 8, 13, 15, 20),
      );

      await pumpAgenda(
        tester,
        appointment: appointment,
        repository: repository,
      );
      await tapClient(tester, 'Ana');

      expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
      expect(find.byType(AppointmentDetailsBottomSheet), findsNothing);
    },
  );

  testWidgets(
    '5: completed não é elegível',
    (tester) async {
      final appointment = currentAppointment(
        clientName: 'Marta',
        status: AppointmentStatus.completed,
      );

      await pumpAgenda(
        tester,
        appointment: appointment,
        repository: idleMemoriesRepository(),
      );
      await tapClient(tester, 'Marta');

      expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
      expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
    },
  );

  testWidgets(
    '5: canceled não é elegível',
    (tester) async {
      final appointment = currentAppointment(
        clientName: 'Rita',
        status: AppointmentStatus.canceled,
      );

      await pumpAgenda(
        tester,
        appointment: appointment,
        repository: idleMemoriesRepository(),
      );
      await tapClient(tester, 'Rita');

      expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
      expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
    },
  );
}
