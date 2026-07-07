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
              (ref, view) async => {
                DateTime(2026, 8, 21),
              },
            ),
          ],
          child: const MaterialApp(
            home: AgendaPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('abre calendário ao tocar no ícone do header', (
      WidgetTester tester,
    ) async {
      await pumpAgendaPage(tester);

      await tester.tap(find.byTooltip(AppStrings.agendaOpenCalendar));
      await tester.pumpAndSettle();

      expect(find.textContaining('2026'), findsWidgets);
    });

    testWidgets('atualiza dia selecionado, chips e cabeçalho após escolha', (
      WidgetTester tester,
    ) async {
      await pumpAgendaPage(tester);

      await tester.tap(find.byTooltip(AppStrings.agendaOpenCalendar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agosto'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('agenda-calendar-day-2026-8-21')));
      await tester.pumpAndSettle();

      final selectedDay = DateTime(2026, 8, 21);
      final expectedHeader = formatAgendaDateLine(
        selectedDay,
        isToday: false,
      );

      expect(find.text(expectedHeader), findsOneWidget);

      final chips = tester.widgetList<AgendaDayChip>(find.byType(AgendaDayChip));
      expect(chips.any((chip) => chip.isSelected && chip.day.day == 21), isTrue);
      expect(
        chips.any((chip) => chip.isSelected && chip.day.month == 8),
        isTrue,
      );
    });

    testWidgets('botão Hoje na agenda retorna para o dia atual', (
      WidgetTester tester,
    ) async {
      await pumpAgendaPage(tester);

      await tester.tap(find.byTooltip(AppStrings.agendaOpenCalendar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agosto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setembro'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('agenda-calendar-day-2026-9-21')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(AppStrings.agendaOpenCalendar));
      await tester.pumpAndSettle();

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

      await tester.tap(find.byTooltip(AppStrings.agendaOpenCalendar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agosto'));
      await tester.pumpAndSettle();

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
            agendaAppointmentsDisplayProvider.overrideWith(
              (ref, day) async {
                loadedDays.add(day);
                return const <AgendaAppointmentDisplay>[];
              },
            ),
            agendaCalendarAppointmentDaysProvider.overrideWith(
              (ref, view) async => const {},
            ),
          ],
          child: const MaterialApp(
            home: AgendaPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      loadedDays.clear();

      await tester.tap(find.byTooltip(AppStrings.agendaOpenCalendar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agosto'));
      await tester.pumpAndSettle();
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
