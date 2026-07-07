import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_bottom_sheet.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_month_grid.dart';

void main() {
  group('AgendaCalendarBottomSheet', () {
    Future<void> pumpCalendar({
      required WidgetTester tester,
      required DateTime initialDate,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showAgendaCalendarBottomSheet(
                        context: context,
                        initialDate: initialDate,
                      );
                    },
                    child: const Text('Abrir'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('abre no mês da data inicial', (WidgetTester tester) async {
      await pumpCalendar(
        tester: tester,
        initialDate: DateTime(2026, 8, 20),
      );

      expect(find.text('Agosto 2026'), findsOneWidget);
      expect(find.text('Julho 2026'), findsNothing);
    });

    testWidgets('retorna a data selecionada e fecha automaticamente', (
      WidgetTester tester,
    ) async {
      late DateTime? selectedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      selectedDate = await showAgendaCalendarBottomSheet(
                        context: context,
                        initialDate: DateTime(2026, 9, 10),
                      );
                    },
                    child: const Text('Abrir'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('agenda-calendar-day-2026-9-21')));
      await tester.pumpAndSettle();

      expect(selectedDate, DateTime(2026, 9, 21));
      expect(find.byType(AgendaCalendarBottomSheet), findsNothing);
    });

    testWidgets('botão Hoje retorna a data atual e fecha', (
      WidgetTester tester,
    ) async {
      late DateTime? selectedDate;
      final today = normalizeCalendarDay(DateTime.now());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      selectedDate = await showAgendaCalendarBottomSheet(
                        context: context,
                        initialDate: DateTime(2026, 3, 5),
                      );
                    },
                    child: const Text('Abrir'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('agenda-calendar-today')));
      await tester.pumpAndSettle();

      expect(selectedDate, today);
      expect(find.byType(AgendaCalendarBottomSheet), findsNothing);
    });

    testWidgets('navega entre meses sem fechar', (WidgetTester tester) async {
      await pumpCalendar(
        tester: tester,
        initialDate: DateTime(2026, 7, 15),
      );

      expect(find.text('Julho 2026'), findsOneWidget);

      await tester.tap(find.text('Agosto'));
      await tester.pumpAndSettle();

      expect(find.text('Agosto 2026'), findsOneWidget);
      expect(find.byType(AgendaCalendarBottomSheet), findsOneWidget);
    });

    testWidgets('exibe o botão Hoje', (WidgetTester tester) async {
      await pumpCalendar(
        tester: tester,
        initialDate: DateTime(2026, 7, 15),
      );

      expect(find.text(AppStrings.appointmentDateToday), findsOneWidget);
    });

    testWidgets('exibe indicador apenas em dias com atendimentos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AgendaCalendarBottomSheet(
            initialDate: DateTime(2026, 7, 15),
            daysWithAppointments: {
              DateTime(2026, 7, 14),
              DateTime(2026, 7, 17),
            },
          ),
        ),
      );

      expect(
        find.byKey(const Key('agenda-calendar-indicator-2026-7-14')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('agenda-calendar-indicator-2026-7-17')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('agenda-calendar-indicator-2026-7-16')),
        findsNothing,
      );
    });

    testWidgets('não exibe indicador quando conjunto de dias está vazio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AgendaCalendarBottomSheet(
            initialDate: DateTime(2026, 7, 15),
          ),
        ),
      );

      expect(
        find.byKey(const Key('agenda-calendar-indicator-2026-7-14')),
        findsNothing,
      );
    });
  });
}
