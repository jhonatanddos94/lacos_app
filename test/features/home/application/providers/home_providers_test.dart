import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/application/providers/home_providers.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  ProviderContainer containerWith(List<AgendaAppointmentDisplay> appointments) {
    final container = ProviderContainer(
      overrides: [
        appClockProvider.overrideWithValue(FakeAppClock(now)),
        calendarTodayProvider.overrideWithValue(today),
        agendaAppointmentsDisplayProvider.overrideWith(
          (ref, day) async => appointments,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> load(ProviderContainer container) {
    return container.read(agendaAppointmentsDisplayProvider(today).future);
  }

  group('homeTodaySummaryProvider', () {
    test('vazio', () async {
      final container = containerWith(const []);
      await load(container);

      expect(container.read(homeTodaySummaryProvider).value!.isEmpty, isTrue);
    });

    test('upcoming, current, overdue, completed e canceled', () async {
      final container = containerWith([
        homeTestAppointment(
          id: 'upcoming',
          clientName: 'Bia',
          startAt: DateTime(2026, 8, 13, 16, 0),
        ),
        homeTestAppointment(
          id: 'current',
          clientName: 'Josefa',
          startAt: DateTime(2026, 8, 13, 13, 30),
        ),
        homeTestAppointment(
          id: 'overdue',
          clientName: 'Atrasada',
          startAt: DateTime(2026, 8, 13, 10, 0),
        ),
        homeTestAppointment(
          id: 'completed',
          clientName: 'Feita',
          startAt: DateTime(2026, 8, 13, 9, 0),
          status: AppointmentStatus.completed,
        ),
        homeTestAppointment(
          id: 'canceled',
          clientName: 'Cancelada',
          startAt: DateTime(2026, 8, 13, 11, 0),
          status: AppointmentStatus.canceled,
        ),
      ]);
      await load(container);

      final summary = container.read(homeTodaySummaryProvider).value!;
      expect(summary.upcomingCount, 1);
      expect(summary.currentCount, 1);
      expect(summary.overdueCount, 1);
      expect(summary.completedCount, 1);
      expect(summary.canceledCount, 1);
    });
  });

  group('homeNextAppointmentProvider', () {
    test(
      'current tem prioridade e ignora overdue/completed/canceled',
      () async {
        final container = containerWith([
          homeTestAppointment(
            id: 'upcoming',
            clientName: 'Bia',
            startAt: DateTime(2026, 8, 13, 16, 0),
          ),
          homeTestAppointment(
            id: 'current',
            clientName: 'Josefa',
            startAt: DateTime(2026, 8, 13, 13, 30),
          ),
          homeTestAppointment(
            id: 'overdue',
            clientName: 'Atrasada',
            startAt: DateTime(2026, 8, 13, 10, 0),
          ),
          homeTestAppointment(
            id: 'completed',
            clientName: 'Feita',
            startAt: DateTime(2026, 8, 13, 9, 0),
            status: AppointmentStatus.completed,
          ),
        ]);
        await load(container);

        expect(
          container.read(homeNextAppointmentProvider).value?.appointmentId,
          'current',
        );
      },
    );

    test('nenhum retorno quando só há overdue', () async {
      final container = containerWith([
        homeTestAppointment(
          id: 'overdue',
          clientName: 'Atrasada',
          startAt: DateTime(2026, 8, 13, 10, 0),
        ),
      ]);
      await load(container);

      expect(container.read(homeNextAppointmentProvider).value, isNull);
    });
  });

  group('homeAttentionProvider', () {
    test('zero overdue', () async {
      final container = containerWith([
        homeTestAppointment(
          id: 'upcoming',
          clientName: 'Bia',
          startAt: DateTime(2026, 8, 13, 16, 0),
        ),
      ]);
      await load(container);

      expect(container.read(homeAttentionProvider).value, isEmpty);
    });

    test('um e vários overdue', () async {
      final one = containerWith([
        homeTestAppointment(
          id: 'overdue',
          clientName: 'Atrasada',
          startAt: DateTime(2026, 8, 13, 10, 0),
        ),
      ]);
      await load(one);
      expect(one.read(homeAttentionProvider).value, hasLength(1));

      final many = containerWith([
        homeTestAppointment(
          id: 'a',
          clientName: 'A',
          startAt: DateTime(2026, 8, 13, 9, 0),
        ),
        homeTestAppointment(
          id: 'b',
          clientName: 'B',
          startAt: DateTime(2026, 8, 13, 11, 0),
        ),
      ]);
      await load(many);
      expect(many.read(homeAttentionProvider).value, hasLength(2));
    });
  });

  test('homeTodayAgendaProvider reutiliza a lista da Agenda do dia', () async {
    final appointments = [
      homeTestAppointment(
        id: 'upcoming',
        clientName: 'Bia',
        startAt: DateTime(2026, 8, 13, 16, 0),
      ),
    ];
    final container = containerWith(appointments);
    await load(container);

    expect(
      container.read(homeTodayAgendaProvider).value,
      same(container.read(agendaAppointmentsDisplayProvider(today)).value),
    );
  });
}
