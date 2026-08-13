import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';
import 'package:lacos_app/features/home/application/services/home_today_summary_formatter.dart';

void main() {
  group('HomeTodaySummaryFormatter', () {
    test('dia vazio mostra agenda livre e CTA', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 0,
        summary: const AgendaOperationalSummary(),
      );

      expect(presentation.isEmpty, isTrue);
      expect(presentation.totalLabel, AppStrings.homeAgendaFreeToday);
      expect(presentation.showNewAppointmentCta, isTrue);
      expect(presentation.operationalLine, isNull);
      expect(presentation.secondaryLine, AppStrings.homeEmptyDayDescription);
    });

    test('não mostra linha 0 concluídos • 0 em andamento • 0 próximos', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 0,
        summary: const AgendaOperationalSummary(),
      );

      expect(presentation.operationalLine, isNull);
      expect(presentation.totalLabel.contains('0'), isFalse);
    });

    test('mostra apenas categorias existentes', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 1,
        summary: const AgendaOperationalSummary(upcomingCount: 1),
      );

      expect(presentation.totalLabel, '1 atendimento');
      expect(presentation.operationalLine, '1 próximo');
    });

    test('combina concluídos, em andamento e próximos', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 5,
        summary: const AgendaOperationalSummary(
          completedCount: 2,
          currentCount: 1,
          upcomingCount: 2,
        ),
      );

      expect(presentation.totalLabel, '5 atendimentos');
      expect(
        presentation.operationalLine,
        '2 concluídos • 1 em andamento • 2 próximos',
      );
    });

    test('não inclui overdue na linha principal', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 3,
        summary: const AgendaOperationalSummary(
          overdueCount: 2,
          upcomingCount: 1,
        ),
      );

      expect(presentation.operationalLine, '1 próximo');
      expect(presentation.operationalLine!.contains('aguardando'), isFalse);
    });

    test('cancelados entram na linha operacional quando existem', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 2,
        summary: const AgendaOperationalSummary(canceledCount: 2),
      );

      expect(presentation.operationalLine, '2 cancelados');
      expect(presentation.secondaryLine, isNull);
    });

    test('concluídos e cancelados compartilham a linha operacional', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 5,
        summary: const AgendaOperationalSummary(
          completedCount: 4,
          canceledCount: 1,
        ),
      );

      expect(presentation.operationalLine, '4 concluídos • 1 cancelado');
    });
  });

  group('HomeAttentionFormatter', () {
    test('zero overdue não gera texto', () {
      expect(HomeAttentionFormatter.format(0), isEmpty);
    });

    test('um overdue usa singular', () {
      expect(
        HomeAttentionFormatter.format(1),
        '1 atendimento aguardando conclusão',
      );
    });

    test('vários overdue usam plural', () {
      expect(
        HomeAttentionFormatter.format(3),
        '3 atendimentos aguardando conclusão',
      );
    });
  });
}
