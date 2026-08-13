import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_chip.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_attention_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_next_appointment_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_quick_actions_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/presentation/pages/app_shell_page.dart';

import '../../../../helpers/home_responsive_test_helpers.dart';
import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  Future<void> pumpCompactShell(
    WidgetTester tester, {
    required TextScaler textScaler,
    List<HomeUpcomingDay>? upcomingDays,
    List<Override> extraOverrides = const [],
    bool withAttention = false,
  }) async {
    final resolvedUpcomingDays = upcomingDays ?? homeUpcomingThreeDays;
    await configureCompactViewport(tester);

    final appointments = withAttention
        ? [
            homeTestAppointment(
              id: 'overdue',
              clientName: 'Ana',
              startAt: DateTime(2026, 8, 13, 10),
              duration: const Duration(hours: 2),
            ),
            homeTestAppointment(
              id: 'next',
              clientName: 'Josefa',
              startAt: DateTime(2026, 8, 13, 16),
            ),
          ]
        : [
            homeTestAppointment(
              id: 'next',
              clientName: 'Josefa',
              startAt: DateTime(2026, 8, 13, 16),
            ),
          ];

    await tester.pumpWidget(
      wrapTextScale(
        textScaler: textScaler,
        child: ProviderScope(
          overrides: [
            appClockProvider.overrideWithValue(FakeAppClock(now)),
            calendarTodayProvider.overrideWithValue(today),
            workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
            agendaAppointmentsDisplayProvider.overrideWith(
              (ref, day) async => appointments,
            ),
            homeUpcomingDaysProvider.overrideWith(
              (ref) async => resolvedUpcomingDays,
            ),
            ...extraOverrides,
          ],
          child: const MaterialApp(home: AppShellPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Home completa compacta', () {
    testWidgets('320x640 textScale 1.3 sem overflow', (tester) async {
      await pumpCompactShell(tester, textScaler: TextScaler.linear(1.3));
      expectNoRenderOverflow(tester);
    });

    testWidgets('320x640 textScale 1.3 scroll até terceira linha', (tester) async {
      await pumpCompactShell(tester, textScaler: TextScaler.linear(1.3));

      final thirdRow = find.byKey(
        HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 17)),
      );
      await scrollHomeToVisible(tester, thirdRow);

      final rowBox = tester.getRect(thirdRow);
      final navBarBox = tester.getRect(find.byType(NavigationBar));
      expect(rowBox.bottom, lessThan(navBarBox.top));
    });

    testWidgets('320x640 textScale 1.3 linha clicável após scroll', (tester) async {
      await pumpCompactShell(tester, textScaler: TextScaler.linear(1.3));

      final tomorrowRow = find.byKey(
        HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 14)),
      );
      await scrollHomeToVisible(tester, tomorrowRow);
      await tester.tap(tomorrowRow);
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        AppShellTab.agenda.index,
      );
      final selected = tester
          .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
          .where((chip) => chip.isSelected)
          .single;
      expect(selected.day.day, 14);
    });

    testWidgets('320x640 textScale 1.3 ações rápidas sem overflow', (tester) async {
      await pumpCompactShell(tester, textScaler: TextScaler.linear(1.3));

      expect(find.byKey(HomeQuickActionsSection.sectionKey), findsOneWidget);
      expect(find.text(AppStrings.homeQuickActionNewAppointment), findsOneWidget);
      expect(find.text(AppStrings.homeQuickActionNewClient), findsOneWidget);
      expect(find.text(AppStrings.homeQuickActionSearchClient), findsOneWidget);
      expectNoRenderOverflow(tester);
    });

    testWidgets('320x640 textScale 1.3 Ver agenda abre hoje', (tester) async {
      await pumpCompactShell(tester, textScaler: TextScaler.linear(1.3));

      await scrollHomeToVisible(
        tester,
        find.byKey(HomeUpcomingDaysSection.openAgendaKey),
      );
      await tester.tap(find.byKey(HomeUpcomingDaysSection.openAgendaKey));
      await tester.pumpAndSettle();

      final selected = tester
          .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
          .where((chip) => chip.isSelected)
          .single;
      expect(selected.day.day, now.day);
      expect(selected.isToday, isTrue);
    });

    testWidgets('320x640 textScale 1.5 estresse máximo realista', (tester) async {
      await pumpCompactShell(
        tester,
        textScaler: TextScaler.linear(1.5),
        upcomingDays: homeUpcomingStressDays,
        withAttention: true,
      );

      expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);
      expect(find.byKey(HomeAttentionSection.sectionKey), findsOneWidget);
      expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsOneWidget);
      expectNoRenderOverflow(tester);

      await scrollHomeToVisible(
        tester,
        find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 12, 31))),
      );
      expectNoRenderOverflow(tester);
    });

    testWidgets('320x640 textScale 1.5 com Atenção separado', (tester) async {
      await pumpCompactShell(
        tester,
        textScaler: TextScaler.linear(1.5),
        withAttention: true,
      );

      expect(find.byKey(HomeAttentionSection.sectionKey), findsOneWidget);
      expectNoRenderOverflow(tester);
    });
  });
}
