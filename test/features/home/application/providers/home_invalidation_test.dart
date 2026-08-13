import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/appointments/application/helpers/appointment_provider_invalidation.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/application/providers/home_providers.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  Future<void> pumpRef(
    WidgetTester tester,
    void Function(WidgetRef ref) onReady, {
    required List<AgendaAppointmentDisplay> Function() load,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => load(),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              onReady(ref);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  testWidgets('create, cancel, complete e update atualizam a Home', (
    tester,
  ) async {
    var items = <AgendaAppointmentDisplay>[];
    late WidgetRef widgetRef;

    await pumpRef(tester, (ref) => widgetRef = ref, load: () => items);

    await tester.runAsync(() async {
      await widgetRef.read(agendaAppointmentsDisplayProvider(today).future);
    });

    expect(widgetRef.read(homeNextAppointmentProvider).value, isNull);
    expect(widgetRef.read(homeTodaySummaryProvider).value!.isEmpty, isTrue);

    items = [
      homeTestAppointment(
        id: 'created',
        clientName: 'Nova',
        startAt: DateTime(2026, 8, 13, 16, 0),
      ),
    ];
    invalidateAppointmentAfterCreate(
      widgetRef,
      clientId: 'client-created',
      day: now,
    );
    await tester.runAsync(() async {
      await widgetRef.read(agendaAppointmentsDisplayProvider(today).future);
    });
    expect(
      widgetRef.read(homeNextAppointmentProvider).value?.clientName,
      'Nova',
    );

    items = [
      homeTestAppointment(
        id: 'updated',
        clientName: 'Nova',
        startAt: DateTime(2026, 8, 13, 17, 0),
      ),
    ];
    invalidateAppointmentAfterUpdate(
      widgetRef,
      appointmentId: 'updated',
      updatedDay: DateTime(2026, 8, 13, 17),
    );
    await tester.runAsync(() async {
      await widgetRef.read(agendaAppointmentsDisplayProvider(today).future);
    });
    expect(
      widgetRef.read(homeNextAppointmentProvider).value?.startAt,
      DateTime(2026, 8, 13, 17),
    );

    items = [
      homeTestAppointment(
        id: 'canceled',
        clientName: 'Nova',
        startAt: DateTime(2026, 8, 13, 17, 0),
        status: AppointmentStatus.canceled,
      ),
    ];
    invalidateAppointmentAfterCancellation(
      widgetRef,
      appointmentId: 'canceled',
      clientId: 'client-created',
      day: DateTime(2026, 8, 13, 17),
    );
    await tester.runAsync(() async {
      await widgetRef.read(agendaAppointmentsDisplayProvider(today).future);
    });
    expect(widgetRef.read(homeNextAppointmentProvider).value, isNull);
    expect(widgetRef.read(homeTodaySummaryProvider).value!.canceledCount, 1);

    items = [
      homeTestAppointment(
        id: 'completed',
        clientName: 'Nova',
        startAt: DateTime(2026, 8, 13, 13, 0),
        status: AppointmentStatus.completed,
      ),
    ];
    invalidateAppointmentAfterCompletion(
      widgetRef,
      appointmentId: 'completed',
      clientId: 'client-created',
      day: DateTime(2026, 8, 13, 13),
    );
    await tester.runAsync(() async {
      await widgetRef.read(agendaAppointmentsDisplayProvider(today).future);
    });
    expect(widgetRef.read(homeNextAppointmentProvider).value, isNull);
    expect(widgetRef.read(homeTodaySummaryProvider).value!.completedCount, 1);
    expect(widgetRef.read(homeAttentionProvider).value, isEmpty);
  });
}
