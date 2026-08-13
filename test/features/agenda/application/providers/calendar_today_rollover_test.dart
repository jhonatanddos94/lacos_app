import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/presentation/pages/agenda_page.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_chip.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_next_appointment_card.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  testWidgets('23:59 → 00:00 troca o AgendaDay observado pela Home', (
    tester,
  ) async {
    final clock = FakeAppClock(DateTime(2026, 8, 13, 23, 59));

    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(clock),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith((ref, day) async {
            if (day == AgendaDay.from(DateTime(2026, 8, 13))) {
              return [
                homeTestAppointment(
                  id: 'today',
                  clientName: 'Josefa',
                  startAt: DateTime(2026, 8, 13, 23, 50),
                  duration: const Duration(minutes: 20),
                ),
              ];
            }

            return [
              homeTestAppointment(
                id: 'tomorrow',
                clientName: 'Carla',
                startAt: DateTime(2026, 8, 14, 9, 0),
              ),
            ];
          }),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Josefa'), findsOneWidget);
    expect(find.text('Carla'), findsNothing);

    clock.setNow(DateTime(2026, 8, 14));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(find.text('Carla'), findsOneWidget);
    expect(find.text('Josefa'), findsNothing);
    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);
  });

  testWidgets('Agenda no modo hoje acompanha a virada do dia', (tester) async {
    final clock = FakeAppClock(DateTime(2026, 8, 13, 23, 59));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(clock),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
        ],
        child: const MaterialApp(home: AgendaPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
          .any((chip) => chip.isSelected && chip.day.day == 13),
      isTrue,
    );

    clock.setNow(DateTime(2026, 8, 14));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
          .any((chip) => chip.isSelected && chip.day.day == 14 && chip.isToday),
      isTrue,
    );
  });

  testWidgets('Agenda com dia manual não é sobrescrita à meia-noite', (
    tester,
  ) async {
    final clock = FakeAppClock(DateTime(2026, 8, 13, 23, 59));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(clock),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
        ],
        child: const MaterialApp(home: AgendaPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AgendaDayChip &&
            widget.day.year == 2026 &&
            widget.day.month == 8 &&
            widget.day.day == 12,
      ),
    );
    await tester.pumpAndSettle();

    clock.setNow(DateTime(2026, 8, 14));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
          .any((chip) => chip.isSelected && chip.day.day == 12),
      isTrue,
    );
  });
}
