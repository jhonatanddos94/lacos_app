import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_quick_actions_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/application/providers/app_shell_providers.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  Future<void> pumpHome(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          homeUpcomingDaysProvider.overrideWith((ref) async => []),
          ...overrides,
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
  }

  testWidgets('loading não bloqueia Home', (tester) async {
    final completer = Completer<List<HomeUpcomingDay>>();

    await pumpHome(
      tester,
      overrides: [
        homeUpcomingDaysProvider.overrideWith((ref) => completer.future),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsNothing);
    expect(find.byKey(HomeQuickActionsSection.sectionKey), findsOneWidget);

    completer.complete(const []);
    await tester.pumpAndSettle();

    expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsNothing);
  });

  testWidgets('erro não quebra Home', (tester) async {
    await pumpHome(
      tester,
      overrides: [
        homeUpcomingDaysProvider.overrideWith((ref) async {
          throw StateError('upcoming-fail');
        }),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsNothing);
    expect(find.textContaining('upcoming-fail'), findsNothing);
    expect(find.byKey(HomeQuickActionsSection.sectionKey), findsOneWidget);
  });

  testWidgets('empty esconde seção', (tester) async {
    await pumpHome(tester, overrides: const []);
    await tester.pumpAndSettle();

    expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsNothing);
  });

  testWidgets('não mostra 4ª linha', (tester) async {
    await pumpHome(
      tester,
      overrides: [
        homeUpcomingDaysProvider.overrideWith(
          (ref) async => [
            HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 1),
            HomeUpcomingDay(day: DateTime(2026, 8, 15), appointmentCount: 2),
            HomeUpcomingDay(day: DateTime(2026, 8, 16), appointmentCount: 3),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appointmentDateTomorrow), findsOneWidget);
    expect(find.text('Sábado, 15 ago.'), findsOneWidget);
    expect(find.text('Domingo, 16 ago.'), findsOneWidget);
    expect(find.text('Segunda, 17 ago.'), findsNothing);
  });

  testWidgets('Ver agenda troca tab corretamente', (tester) async {
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
          homeUpcomingDaysProvider.overrideWith(
            (ref) async => [
              HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 1),
            ],
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const HomePage();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeUpcomingDaysSection.openAgendaKey));
    await tester.pump();

    expect(widgetRef.read(appShellTabProvider), AppShellTab.agenda);
  });

  testWidgets('sem Appointment cards na seção', (tester) async {
    await pumpHome(
      tester,
      overrides: [
        homeUpcomingDaysProvider.overrideWith(
          (ref) async => [
            HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 2),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('ações rápidas continuam funcionando', (tester) async {
    await pumpHome(
      tester,
      overrides: [
        homeUpcomingDaysProvider.overrideWith(
          (ref) async => [
            HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 2),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeQuickActionsSection.newAppointmentKey));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appointmentFormCreateTitle), findsOneWidget);
  });
}
