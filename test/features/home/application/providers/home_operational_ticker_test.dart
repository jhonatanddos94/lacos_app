import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_attention_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_next_appointment_card.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  testWidgets(
    '15:59 → 16:00 promove upcoming para current sem nova query remota',
    (tester) async {
      final clock = FakeAppClock(DateTime(2026, 8, 13, 15, 59));
      var loads = 0;
      final today = AgendaDay.from(clock.now());

      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appClockProvider.overrideWithValue(clock),
            calendarTodayProvider.overrideWithValue(today),
            workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
            agendaAppointmentsDisplayProvider.overrideWith((ref, day) async {
              loads++;
              return [
                homeTestAppointment(
                  id: 'slot',
                  clientName: 'Josefa',
                  startAt: DateTime(2026, 8, 13, 16, 0),
                ),
              ];
            }),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.homeNextAppointmentTitle), findsOneWidget);
      expect(
        find.text(AppStrings.appointmentOperationalStateNextLabel),
        findsOneWidget,
      );
      expect(loads, 1);

      clock.setNow(DateTime(2026, 8, 13, 16, 0));
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.homeInProgressTitle), findsOneWidget);
      expect(
        find.text(AppStrings.appointmentOperationalStateCurrentLabel),
        findsOneWidget,
      );
      expect(find.text(AppStrings.homeNextAppointmentTitle), findsNothing);
      expect(loads, 1);
    },
  );

  testWidgets('endAt promove current para overdue sem nova query remota', (
    tester,
  ) async {
    final clock = FakeAppClock(DateTime(2026, 8, 13, 14, 29));
    var loads = 0;
    final today = AgendaDay.from(clock.now());

    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(clock),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith((ref, day) async {
            loads++;
            return [
              homeTestAppointment(
                id: 'current',
                clientName: 'Josefa',
                startAt: DateTime(2026, 8, 13, 13, 30),
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeInProgressTitle), findsOneWidget);
    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);
    expect(find.byKey(HomeAttentionSection.sectionKey), findsNothing);
    expect(loads, 1);

    clock.setNow(DateTime(2026, 8, 13, 14, 30));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsNothing);
    expect(find.byKey(HomeAttentionSection.sectionKey), findsOneWidget);
    expect(loads, 1);
  });
}
