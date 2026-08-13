import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_date_formatters.dart';
import 'package:lacos_app/features/agenda/presentation/pages/agenda_page.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_chip.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_month_grid.dart';

void main() {
  group('AgendaPage calendar navigation', () {
    Future<void> pumpAgendaPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agendaAppointmentsDisplayProvider.overrideWith(
              (ref, day) async => const <AgendaAppointmentDisplay>[],
            ),
            agendaCalendarAppointmentDaysProvider.overrideWith(
              (ref, view) async => {DateTime(2026, 8, 21)},
            ),
          ],
          child: const MaterialApp(home: AgendaPage()),
        ),
      );

      await tester.pumpAndSettle();
    }

    Future<void> openCalendar(WidgetTester tester) async {
      await tester.tap(find.byTooltip(AppStrings.agendaOpenCalendar));
      await tester.pumpAndSettle();
    }

    testWidgets('abre calendário ao tocar no ícone do header', (
      WidgetTester tester,
    ) async {
      await pumpAgendaPage(tester);

      await openCalendar(tester);

      expect(find.textContaining('2026'), findsWidgets);
    });

    testWidgets('atualiza dia selecionado, chips e cabeçalho após escolha', (
      WidgetTester tester,
    ) async {
      await pumpAgendaPage(tester);

      await openCalendar(tester);
      await _navigateToMonth(tester, year: 2026, month: 8);
      await tester.tap(find.byKey(const Key('agenda-calendar-day-2026-8-21')));
      await tester.pumpAndSettle();

      final selectedDay = DateTime(2026, 8, 21);
      final expectedHeader = formatAgendaDateLine(selectedDay, isToday: false);

      expect(find.text(expectedHeader), findsOneWidget);

      final chips = tester.widgetList<AgendaDayChip>(
        find.byType(AgendaDayChip),
      );
      expect(
        chips.any((chip) => chip.isSelected && chip.day.day == 21),
        isTrue,
      );
      expect(
        chips.any((chip) => chip.isSelected && chip.day.month == 8),
        isTrue,
      );
    });

    testWidgets('botão Hoje na agenda retorna para o dia atual', (
      WidgetTester tester,
    ) async {
      await pumpAgendaPage(tester);

      await openCalendar(tester);
      await _navigateToMonth(tester, year: 2026, month: 9);

      await tester.tap(find.byKey(const Key('agenda-calendar-day-2026-9-21')));
      await tester.pumpAndSettle();

      await openCalendar(tester);

      await tester.tap(find.byKey(const Key('agenda-calendar-today')));
      await tester.pumpAndSettle();

      final today = DateTime.now();
      final expectedHeader = formatAgendaDateLine(
        DateTime(today.year, today.month, today.day),
        isToday: true,
      );

      expect(find.text(expectedHeader), findsOneWidget);
    });

    testWidgets('exibe indicadores de atendimentos no calendário', (
      WidgetTester tester,
    ) async {
      await pumpAgendaPage(tester);

      await openCalendar(tester);
      await _navigateToMonth(tester, year: 2026, month: 8);

      expect(
        find.byKey(const Key('agenda-calendar-indicator-2026-8-21')),
        findsOneWidget,
      );
    });

    testWidgets('recarrega lista ao mudar o dia via calendário', (
      WidgetTester tester,
    ) async {
      var loadedDays = <AgendaDay>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agendaAppointmentsDisplayProvider.overrideWith((ref, day) async {
              loadedDays.add(day);
              return const <AgendaAppointmentDisplay>[];
            }),
            agendaCalendarAppointmentDaysProvider.overrideWith(
              (ref, view) async => const {},
            ),
          ],
          child: const MaterialApp(home: AgendaPage()),
        ),
      );

      await tester.pumpAndSettle();
      loadedDays.clear();

      await openCalendar(tester);
      await _navigateToMonth(tester, year: 2026, month: 8);
      await tester.tap(find.byKey(const Key('agenda-calendar-day-2026-8-21')));
      await tester.pumpAndSettle();

      expect(
        loadedDays.any(
          (day) => day.year == 2026 && day.month == 8 && day.day == 21,
        ),
        isTrue,
      );
    });
  });
}

Future<void> _navigateToMonth(
  WidgetTester tester, {
  required int year,
  required int month,
}) async {
  final targetTitle = '${AgendaCalendarMonthGrid.monthName(month)} $year';

  for (var step = 0; step < 36; step++) {
    if (find.text(targetTitle).evaluate().isNotEmpty) {
      return;
    }

    final titleFinder = find.textContaining(RegExp(r'\d{4}$'));
    expect(titleFinder, findsWidgets);

    final titleText = tester.widget<Text>(titleFinder.first).data ?? '';
    final currentMonth = _monthFromTitle(titleText);
    final currentYear = _yearFromTitle(titleText) ?? year;

    final currentIndex = currentYear * 12 + currentMonth;
    final targetIndex = year * 12 + month;

    if (targetIndex > currentIndex) {
      final nextLabel = AgendaCalendarMonthGrid.monthName(
        currentMonth == 12 ? 1 : currentMonth + 1,
      );
      await tester.tap(find.text(nextLabel));
    } else if (targetIndex < currentIndex) {
      final previousLabel = AgendaCalendarMonthGrid.monthName(
        currentMonth == 1 ? 12 : currentMonth - 1,
      );
      await tester.tap(find.text(previousLabel));
    } else {
      return;
    }
    await tester.pumpAndSettle();
  }

  fail('Calendário não chegou em $year-$month.');
}

int _monthFromTitle(String title) {
  for (var month = 1; month <= 12; month++) {
    final name = AgendaCalendarMonthGrid.monthName(month);
    if (title.startsWith(name)) {
      return month;
    }
  }
  fail('Mês não reconhecido no título do calendário: $title');
}

int? _yearFromTitle(String title) {
  final match = RegExp(r'(\d{4})').firstMatch(title);
  return match == null ? null : int.parse(match.group(1)!);
}
