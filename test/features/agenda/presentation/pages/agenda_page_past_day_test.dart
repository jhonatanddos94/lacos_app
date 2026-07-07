import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/presentation/pages/agenda_page.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_day_chip.dart';

void main() {
  group('AgendaPage past days', () {
    Future<void> pumpAgendaPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agendaAppointmentsDisplayProvider.overrideWith(
              (ref, day) async => const <AgendaAppointmentDisplay>[],
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
    }

    Future<void> selectDay(WidgetTester tester, DateTime day) async {
      final normalizedDay = normalizeAppointmentDate(day);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AgendaDayChip &&
              normalizeAppointmentDate(widget.day) == normalizedDay,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('oculta botão Novo em dia passado', (WidgetTester tester) async {
      await pumpAgendaPage(tester);

      expect(find.text('Novo'), findsOneWidget);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await selectDay(tester, yesterday);

      expect(find.text('Novo'), findsNothing);
    });

    testWidgets('exibe mensagem histórica quando dia passado está vazio', (
      WidgetTester tester,
    ) async {
      await pumpAgendaPage(tester);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await selectDay(tester, yesterday);

      expect(find.text(AppStrings.agendaEmptyPastDay), findsOneWidget);
      expect(find.text(AppStrings.agendaEmptyDay), findsNothing);
      expect(find.textContaining(AppStrings.agendaHistoricalDayLabel), findsWidgets);
    });

    testWidgets('mantém botão Novo em dia operacional', (WidgetTester tester) async {
      await pumpAgendaPage(tester);

      expect(find.text('Novo'), findsOneWidget);

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await selectDay(tester, tomorrow);

      expect(find.text('Novo'), findsOneWidget);
      expect(find.text(AppStrings.agendaEmptyDay), findsOneWidget);
      expect(find.text(AppStrings.agendaEmptyPastDay), findsNothing);
    });
  });
}
