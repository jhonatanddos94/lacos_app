import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';
import 'package:lacos_app/features/home/application/services/home_today_summary_formatter.dart';

void main() {
  group('HomeTodaySummaryFormatter — dia livre', () {
    test('A/B: dia vazio interpreta o dia sem mostrar zeros', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 0,
        summary: const AgendaOperationalSummary(),
      );

      expect(presentation.state, HomeTodayCardState.freeDay);
      expect(presentation.isEmpty, isTrue);
      expect(presentation.title, AppStrings.homeAgendaFreeToday);
      expect(presentation.secondaryLine, AppStrings.homeEmptyDayDescription);
      expect(presentation.warmLine, AppStrings.homeTodayFreeDayWarmLine);
      expect(presentation.showNewAppointmentCta, isTrue);
      expect(presentation.operationalLine, isNull);
      expect(presentation.nextTimeLabel, isNull);
      expect(presentation.title.contains('0'), isFalse);
    });

    test('S: semantics do dia livre descreve o estado', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 0,
        summary: const AgendaOperationalSummary(),
      );

      expect(
        presentation.semanticsLabel,
        'Hoje. Seu dia está livre. Nenhum atendimento para hoje.',
      );
    });
  });

  group('HomeTodaySummaryFormatter — dia em andamento', () {
    test('F/J: upcoming vira dia em andamento sem zeros', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 1,
        summary: const AgendaOperationalSummary(upcomingCount: 1),
      );

      expect(presentation.state, HomeTodayCardState.activeDay);
      expect(presentation.title, '1 atendimento hoje');
      expect(presentation.operationalLine, '1 próximo');
      expect(presentation.warmLine, isNull);
      expect(presentation.showNewAppointmentCta, isFalse);
    });

    test('E: current sozinho mantém o dia em andamento', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 1,
        summary: const AgendaOperationalSummary(currentCount: 1),
      );

      expect(presentation.state, HomeTodayCardState.activeDay);
      expect(presentation.title, '1 atendimento hoje');
      expect(presentation.operationalLine, '1 em andamento');
    });

    test('D/G/I: plural e contadores combinados', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 5,
        summary: const AgendaOperationalSummary(
          completedCount: 2,
          currentCount: 1,
          upcomingCount: 2,
        ),
      );

      expect(presentation.title, '5 atendimentos hoje');
      expect(
        presentation.operationalLine,
        '2 concluídos • 1 em andamento • 2 próximos',
      );
    });

    test('H: próximo horário aparece quando há upcoming', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 2,
        summary: const AgendaOperationalSummary(
          completedCount: 1,
          upcomingCount: 1,
        ),
        nextUpcomingStartAt: DateTime(2026, 8, 13, 14, 30),
      );

      expect(presentation.nextTimeLabel, 'Próximo às 14:30');
    });

    test('H: sem upcoming real não existe pill de próximo horário', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 1,
        summary: const AgendaOperationalSummary(currentCount: 1),
      );

      expect(presentation.nextTimeLabel, isNull);
    });

    test('K: overdue mantém pendência e fica fora da linha operacional', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 3,
        summary: const AgendaOperationalSummary(
          overdueCount: 2,
          upcomingCount: 1,
        ),
      );

      expect(presentation.state, HomeTodayCardState.activeDay);
      expect(presentation.title, isNot(AppStrings.homeTodayFinishedTitle));
      expect(presentation.operationalLine, '1 próximo');
      expect(presentation.operationalLine, isNot(contains('aguardando')));
    });

    test('K: overdue sozinho não celebra o dia', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 1,
        summary: const AgendaOperationalSummary(overdueCount: 1),
      );

      expect(presentation.state, HomeTodayCardState.activeDay);
      expect(presentation.title, '1 atendimento hoje');
      expect(presentation.operationalLine, isNull);
      expect(presentation.warmLine, isNull);
    });

    test('T: semantics do dia em andamento inclui próximo horário', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 2,
        summary: const AgendaOperationalSummary(
          completedCount: 1,
          upcomingCount: 1,
        ),
        nextUpcomingStartAt: DateTime(2026, 8, 13, 14, 30),
      );

      expect(
        presentation.semanticsLabel,
        'Hoje. 2 atendimentos hoje. 1 concluído, 1 próximo. Próximo às 14:30.',
      );
    });
  });

  group('HomeTodaySummaryFormatter — dia encerrado', () {
    test('C: um concluído encerra o dia com acolhimento', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 1,
        summary: const AgendaOperationalSummary(completedCount: 1),
      );

      expect(presentation.state, HomeTodayCardState.finishedDay);
      expect(presentation.isEmpty, isFalse);
      expect(presentation.title, AppStrings.homeTodayFinishedTitle);
      expect(presentation.operationalLine, '1 atendimento concluído');
      expect(presentation.warmLine, AppStrings.homeTodayFinishedWarmLine);
      expect(presentation.nextTimeLabel, isNull);
      expect(presentation.showNewAppointmentCta, isFalse);
    });

    test('D: vários concluídos usam plural', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 3,
        summary: const AgendaOperationalSummary(completedCount: 3),
      );

      expect(presentation.operationalLine, '3 atendimentos concluídos');
    });

    test('L: cancelados aparecem junto dos concluídos', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 5,
        summary: const AgendaOperationalSummary(
          completedCount: 4,
          canceledCount: 1,
        ),
      );

      expect(presentation.title, AppStrings.homeTodayFinishedTitle);
      expect(presentation.operationalLine, '4 atendimentos concluídos • 1 cancelado');
    });

    test('L: dia só com cancelados recebe título neutro', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 2,
        summary: const AgendaOperationalSummary(canceledCount: 2),
      );

      expect(presentation.state, HomeTodayCardState.finishedDay);
      expect(presentation.title, AppStrings.homeTodayNothingLeftTitle);
      expect(presentation.title, isNot(AppStrings.homeTodayFinishedTitle));
      expect(presentation.operationalLine, '2 atendimentos cancelados');
      expect(presentation.warmLine, isNull);
      expect(presentation.secondaryLine, isNull);
    });

    test('U: semantics do dia encerrado descreve o concluído', () {
      final presentation = HomeTodaySummaryFormatter.format(
        totalCount: 1,
        summary: const AgendaOperationalSummary(completedCount: 1),
      );

      expect(
        presentation.semanticsLabel,
        'Hoje. Tudo certo por hoje. 1 atendimento concluído.',
      );
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
