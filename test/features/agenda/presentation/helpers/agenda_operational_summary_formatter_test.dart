import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_operational_summary_formatter.dart';

void main() {
  group('formatAgendaOperationalSummaryLine', () {
    test('mostra apenas categorias com quantidade maior que zero', () {
      expect(
        formatAgendaOperationalSummaryLine(
          const AgendaOperationalSummary(
            overdueCount: 2,
            currentCount: 1,
            upcomingCount: 4,
          ),
        ),
        '2 ${AppStrings.agendaOperationalSummaryOverdue} • '
        '1 ${AppStrings.agendaOperationalSummaryCurrent} • '
        '4 ${AppStrings.agendaOperationalSummaryUpcoming}',
      );
    });

    test('mostra apenas em andamento quando é a única categoria ativa', () {
      expect(
        formatAgendaOperationalSummaryLine(
          const AgendaOperationalSummary(currentCount: 1),
        ),
        '1 ${AppStrings.agendaOperationalSummaryCurrent}',
      );
    });

    test('mostra overdue e upcoming sem current', () {
      expect(
        formatAgendaOperationalSummaryLine(
          const AgendaOperationalSummary(overdueCount: 2, upcomingCount: 3),
        ),
        '2 ${AppStrings.agendaOperationalSummaryOverdue} • '
        '3 ${AppStrings.agendaOperationalSummaryUpcoming}',
      );
    });

    test('retorna nenhum atendimento quando não há itens ativos', () {
      expect(
        formatAgendaOperationalSummaryLine(const AgendaOperationalSummary()),
        AppStrings.agendaOperationalSummaryNone,
      );

      expect(
        formatAgendaOperationalSummaryLine(
          const AgendaOperationalSummary(completedCount: 2, canceledCount: 1),
        ),
        AppStrings.agendaOperationalSummaryNone,
      );
    });
  });
}
