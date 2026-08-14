import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_theme.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/agenda/presentation/pages/agenda_page.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_chip.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/clients_page.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_quick_actions_section.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_today_summary_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/presentation/pages/services_page.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/presentation/pages/app_shell_page.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  Future<void> pumpShell(WidgetTester tester) async {
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
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          servicesProvider.overrideWith((ref) async => const <Service>[]),
          homeUpcomingDaysProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpShellWithUpcomingDays(WidgetTester tester) async {
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
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          servicesProvider.overrideWith((ref) async => const <Service>[]),
          homeUpcomingDaysProvider.overrideWith(
            (ref) async => [
              HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 1),
              HomeUpcomingDay(day: DateTime(2026, 8, 15), appointmentCount: 2),
            ],
          ),
        ],
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  AgendaDayChip selectedChip(WidgetTester tester) {
    return tester
        .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
        .where((chip) => chip.isSelected)
        .single;
  }

  testWidgets('Home troca para a tab Agenda sem empilhar outra Agenda', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(AgendaPage, skipOffstage: false), findsOneWidget);

    final navBefore = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBefore.selectedIndex, AppShellTab.home.index);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    final navAfter = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navAfter.selectedIndex, AppShellTab.agenda.index);

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, AppShellTab.agenda.index);
    expect(find.byType(AgendaPage), findsOneWidget);
    expect(find.byType(AgendaPage, skipOffstage: false), findsOneWidget);
  });

  testWidgets('tab Mais mostra administração secundária real', (tester) async {
    await pumpShell(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Mais'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppShellTab.more.index,
    );
    expect(find.text('Mais em breve'), findsNothing);
    expect(find.text(AppStrings.mySalon), findsOneWidget);
    expect(find.text(AppStrings.profile), findsOneWidget);
    expect(find.text(AppStrings.moreHelpSupport), findsOneWidget);
    expect(find.text(AppStrings.moreAbout), findsOneWidget);
    expect(find.text(AppStrings.logout), findsNothing);
  });

  testWidgets('tab Serviços mostra o catálogo e não o placeholder', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Serviços'),
      ),
    );
    await tester.pumpAndSettle();

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, AppShellTab.services.index);
    expect(find.byType(ServicesPage), findsOneWidget);
    expect(find.text('Serviços em breve'), findsNothing);
    expect(find.text(AppStrings.servicesEmptyTitle), findsOneWidget);
  });

  testWidgets('IndexedStack preserva o estado da Agenda na troca pela nav', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AgendaDayChip &&
            widget.day.year == yesterday.year &&
            widget.day.month == yesterday.month &&
            widget.day.day == yesterday.day,
      ),
    );
    await tester.pumpAndSettle();

    final selectedBeforeHome = tester
        .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
        .where((chip) => chip.isSelected)
        .single;
    expect(selectedBeforeHome.day.day, yesterday.day);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    final selectedAfterReturn = tester
        .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
        .where((chip) => chip.isSelected)
        .single;
    expect(selectedAfterReturn.day.day, yesterday.day);
  });

  testWidgets('resumo HOJE foca a Agenda no dia atual após outra seleção', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => [
              homeTestAppointment(
                id: 'upcoming',
                clientName: 'Bia',
                startAt: DateTime(2026, 8, 13, 16, 0),
              ),
            ],
          ),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          servicesProvider.overrideWith((ref) async => const <Service>[]),
        ],
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AgendaDayChip &&
            widget.day.year == yesterday.year &&
            widget.day.month == yesterday.month &&
            widget.day.day == yesterday.day,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeTodaySummarySection.sectionKey));
    await tester.pumpAndSettle();

    final selected = tester
        .widgetList<AgendaDayChip>(find.byType(AgendaDayChip))
        .where((chip) => chip.isSelected)
        .single;
    expect(selected.day.day, now.day);
    expect(selected.isToday, isTrue);
  });

  testWidgets('Buscar cliente abre a tab Clientes e foca a busca', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.byKey(HomeQuickActionsSection.searchClientKey));
    await tester.pumpAndSettle();

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, AppShellTab.clients.index);
    expect(find.byType(ClientsPage), findsOneWidget);

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(ClientsPage.searchBarKey),
        matching: find.byType(TextField),
      ),
    );
    expect(field.focusNode?.hasFocus, isTrue);
  });

  testWidgets('Shell usa ícones escuros na status bar sobre fundo claro', (
    tester,
  ) async {
    await pumpShell(tester);

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    expect(region.value.statusBarColor, Colors.transparent);
    expect(region.value.statusBarIconBrightness, Brightness.dark);
    expect(region.value.statusBarBrightness, Brightness.light);
    expect(region.value, AppTheme.lightStatusBarOverlay);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();

    final regionAfterTab = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    expect(regionAfterTab.value, AppTheme.lightStatusBarOverlay);
  });

  testWidgets('Próximos dias: tocar amanhã abre Agenda no dia correto', (
    tester,
  ) async {
    await pumpShellWithUpcomingDays(tester);

    await tester.tap(
      find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 14))),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      AppShellTab.agenda.index,
    );
    expect(selectedChip(tester).day.day, 14);
    expect(find.byType(AgendaPage), findsOneWidget);
  });

  testWidgets('Próximos dias: tocar data específica seleciona o dia', (
    tester,
  ) async {
    await pumpShellWithUpcomingDays(tester);

    await tester.tap(
      find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 15))),
    );
    await tester.pumpAndSettle();

    expect(selectedChip(tester).day.day, 15);
  });

  testWidgets('Próximos dias: datas diferentes em sequência', (tester) async {
    await pumpShellWithUpcomingDays(tester);

    await tester.tap(
      find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 14))),
    );
    await tester.pumpAndSettle();
    expect(selectedChip(tester).day.day, 14);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 15))),
    );
    await tester.pumpAndSettle();
    expect(selectedChip(tester).day.day, 15);
  });

  testWidgets('Próximos dias: mesmo dia novamente continua funcionando', (
    tester,
  ) async {
    await pumpShellWithUpcomingDays(tester);

    final row = find.byKey(
      HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 15)),
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(selectedChip(tester).day.day, 15);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(selectedChip(tester).day.day, 15);
  });

  testWidgets('Próximos dias: Agenda já ativa apenas muda o dia', (
    tester,
  ) async {
    await pumpShellWithUpcomingDays(tester);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AgendaDayChip &&
            widget.day.year == yesterday.year &&
            widget.day.month == yesterday.month &&
            widget.day.day == yesterday.day,
      ),
    );
    await tester.pumpAndSettle();
    expect(selectedChip(tester).day.day, yesterday.day);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 14))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AgendaPage), findsOneWidget);
    expect(selectedChip(tester).day.day, 14);
  });

  testWidgets('Ver agenda abre hoje e linha abre o dia da linha', (
    tester,
  ) async {
    await pumpShellWithUpcomingDays(tester);

    await tester.tap(find.byKey(HomeUpcomingDaysSection.openAgendaKey));
    await tester.pumpAndSettle();
    expect(selectedChip(tester).day.day, now.day);
    expect(selectedChip(tester).isToday, isTrue);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 15))),
    );
    await tester.pumpAndSettle();
    expect(selectedChip(tester).day.day, 15);
  });

  testWidgets('Próximos dias observa provider apenas do dia selecionado', (
    tester,
  ) async {
    final requestedDays = <AgendaDay>[];

    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith((ref, day) async {
            requestedDays.add(day);
            return const [];
          }),
          agendaCalendarAppointmentDaysProvider.overrideWith(
            (ref, view) async => const {},
          ),
          clientsProvider.overrideWith((ref) async => const <Client>[]),
          servicesProvider.overrideWith((ref) async => const <Service>[]),
          homeUpcomingDaysProvider.overrideWith(
            (ref) async => [
              HomeUpcomingDay(day: DateTime(2026, 8, 15), appointmentCount: 1),
            ],
          ),
        ],
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    requestedDays.clear();

    await tester.tap(
      find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 15))),
    );
    await tester.pumpAndSettle();

    expect(requestedDays.where((day) => day.day == 15), isNotEmpty);
    expect(requestedDays.where((day) => day.day == 14), isEmpty);
  });
}
