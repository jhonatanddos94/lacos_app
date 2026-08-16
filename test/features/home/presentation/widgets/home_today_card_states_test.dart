import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/theme/app_theme.dart';
import 'package:lacos_app/core/theme/app_typography.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_attention_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_next_appointment_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_today_summary_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';
import 'package:lacos_app/features/monetization/presentation/widgets/home_ad_slot.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/application/providers/app_shell_providers.dart';

import '../../../../helpers/home_responsive_test_helpers.dart';
import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  var loads = 0;

  setUp(() => loads = 0);

  Future<void> pumpHome(
    WidgetTester tester, {
    required List<AgendaAppointmentDisplay> appointments,
    Size size = const Size(400, 900),
    TextScaler textScaler = TextScaler.noScaling,
    List<HomeUpcomingDay> upcomingDays = const [],
    List<Override> extraOverrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: ProviderScope(
          overrides: [
            appClockProvider.overrideWithValue(FakeAppClock(now)),
            calendarTodayProvider.overrideWithValue(today),
            workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
            agendaAppointmentsDisplayProvider.overrideWith((ref, day) async {
              loads++;
              return appointments;
            }),
            homeUpcomingDaysProvider.overrideWith((ref) async => upcomingDays),
            ...extraOverrides,
          ],
          child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AgendaAppointmentDisplay completed(String id, int hour) {
    return homeTestAppointment(
      id: id,
      clientName: 'Concluída $id',
      startAt: DateTime(2026, 8, 13, hour),
      status: AppointmentStatus.completed,
    );
  }

  AgendaAppointmentDisplay upcoming(String id, int hour, [int minute = 0]) {
    return homeTestAppointment(
      id: id,
      clientName: 'Próxima $id',
      startAt: DateTime(2026, 8, 13, hour, minute),
    );
  }

  group('dia livre', () {
    testWidgets('A/B: mostra o dia livre sem contador zerado', (tester) async {
      await pumpHome(tester, appointments: const []);

      expect(find.text(AppStrings.homeAgendaFreeToday), findsOneWidget);
      expect(find.text(AppStrings.homeEmptyDayDescription), findsOneWidget);
      expect(find.text(AppStrings.homeTodayFreeDayWarmLine), findsOneWidget);
      expect(find.text('0 atendimentos'), findsNothing);
      expect(find.textContaining('0 '), findsNothing);
      expect(find.byIcon(Icons.local_cafe_outlined), findsOneWidget);
      expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byKey(HomeTodaySummarySection.todayBadgeKey), findsOneWidget);
      expect(find.byKey(HomeTodaySummarySection.nextTimePillKey), findsNothing);
      expect(
        find.byKey(HomeTodaySummarySection.newAppointmentCtaKey),
        findsOneWidget,
      );
    });

    testWidgets('S: semantics anuncia o estado livre completo', (tester) async {
      await pumpHome(tester, appointments: const []);

      expect(
        find.bySemanticsLabel(
          'Hoje. Seu dia está livre. Nenhum atendimento para hoje.',
        ),
        findsOneWidget,
      );
    });
  });

  group('dia em andamento', () {
    testWidgets('F/H: upcoming mostra total e pill de próximo horário', (
      tester,
    ) async {
      await pumpHome(tester, appointments: [upcoming('a', 16, 30)]);

      expect(find.text('1 atendimento hoje'), findsOneWidget);
      expect(find.text('1 próximo'), findsOneWidget);
      expect(find.text('Próximo às 16:30'), findsOneWidget);
      expect(find.byKey(HomeTodaySummarySection.statusIndicatorsKey), findsOneWidget);
      expect(find.byKey(HomeTodaySummarySection.nextTimePillKey), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.text(AppStrings.homeTodayFinishedTitle), findsNothing);
    });

    testWidgets('E/H: current sozinho não aponta próximo horário', (
      tester,
    ) async {
      await pumpHome(
        tester,
        appointments: [
          homeTestAppointment(
            id: 'current',
            clientName: 'Josefa',
            startAt: DateTime(2026, 8, 13, 13, 30),
          ),
        ],
      );

      expect(find.text('1 atendimento hoje'), findsOneWidget);
      expect(find.text('1 em andamento'), findsOneWidget);
      expect(find.byKey(HomeTodaySummarySection.nextTimePillKey), findsNothing);
      expect(find.textContaining(AppStrings.homeTodayNextAtPrefix), findsNothing);
    });

    testWidgets('G/H: current + upcoming aponta o próximo real', (tester) async {
      await pumpHome(
        tester,
        appointments: [
          homeTestAppointment(
            id: 'current',
            clientName: 'Josefa',
            startAt: DateTime(2026, 8, 13, 13, 30),
          ),
          upcoming('later', 18),
          upcoming('sooner', 16),
        ],
      );

      expect(find.text('3 atendimentos hoje'), findsOneWidget);
      expect(find.text('1 em andamento'), findsOneWidget);
      expect(find.text('2 próximos'), findsOneWidget);
      expect(find.text('Próximo às 16:00'), findsOneWidget);
      expect(find.text('Próximo às 13:30'), findsNothing);
    });

    testWidgets('I/J: completed + upcoming somam sem mostrar zeros', (
      tester,
    ) async {
      await pumpHome(
        tester,
        appointments: [completed('done', 9), upcoming('next', 16)],
      );

      expect(find.text('2 atendimentos hoje'), findsOneWidget);
      expect(find.text('1 concluído'), findsOneWidget);
      expect(find.text('1 próximo'), findsOneWidget);
      expect(find.textContaining('0 em andamento'), findsNothing);
      expect(find.textContaining('0 cancelado'), findsNothing);
    });

    testWidgets('T: semantics anuncia contadores e próximo horário', (
      tester,
    ) async {
      await pumpHome(
        tester,
        appointments: [completed('done', 9), upcoming('next', 14, 30)],
      );

      expect(
        find.bySemanticsLabel(
          'Hoje. 2 atendimentos hoje. 1 concluído, 1 próximo. '
          'Próximo às 14:30.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('K/M: overdue não vira Tudo certo e mantém Atenção', (
      tester,
    ) async {
      await pumpHome(
        tester,
        appointments: [
          homeTestAppointment(
            id: 'overdue',
            clientName: 'Atrasada',
            startAt: DateTime(2026, 8, 13, 10),
          ),
        ],
      );

      expect(find.text(AppStrings.homeTodayFinishedTitle), findsNothing);
      expect(find.text(AppStrings.homeTodayFinishedWarmLine), findsNothing);
      expect(find.text('1 atendimento hoje'), findsOneWidget);
      expect(find.byKey(HomeAttentionSection.sectionKey), findsOneWidget);
      expect(find.text('1 atendimento aguardando conclusão'), findsOneWidget);
    });

    testWidgets('N: card operacional de próximo continua abaixo do resumo', (
      tester,
    ) async {
      await pumpHome(tester, appointments: [upcoming('next', 16)]);

      expect(find.byKey(HomeTodaySummarySection.sectionKey), findsOneWidget);
      expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsOneWidget);

      final summaryBottom = tester
          .getBottomLeft(find.byKey(HomeTodaySummarySection.sectionKey))
          .dy;
      final nextTop = tester
          .getTopLeft(find.byKey(HomeNextAppointmentCard.sectionKey))
          .dy;
      expect(nextTop, greaterThanOrEqualTo(summaryBottom));
      expect(find.text('Próxima next'), findsOneWidget);
    });
  });

  group('dia encerrado', () {
    testWidgets('C: um concluído encerra o dia com acolhimento', (tester) async {
      await pumpHome(tester, appointments: [completed('done', 9)]);

      expect(find.text(AppStrings.homeTodayFinishedTitle), findsOneWidget);
      expect(find.text('1 atendimento concluído'), findsOneWidget);
      expect(find.text(AppStrings.homeTodayFinishedWarmLine), findsOneWidget);
      expect(find.byKey(HomeTodaySummarySection.completedCheckKey), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byKey(HomeTodaySummarySection.nextTimePillKey), findsNothing);
      expect(find.byKey(HomeNextAppointmentCard.sectionKey), findsNothing);
      expect(find.text(AppStrings.homeAgendaFreeToday), findsNothing);
    });

    testWidgets('D: vários concluídos usam plural', (tester) async {
      await pumpHome(
        tester,
        appointments: [completed('a', 8), completed('b', 9), completed('c', 10)],
      );

      expect(find.text(AppStrings.homeTodayFinishedTitle), findsOneWidget);
      expect(find.text('3 atendimentos concluídos'), findsOneWidget);
    });

    testWidgets('L: dia só com cancelados não é celebrado', (tester) async {
      await pumpHome(
        tester,
        appointments: [
          homeTestAppointment(
            id: 'canceled',
            clientName: 'Cancelada',
            startAt: DateTime(2026, 8, 13, 9),
            status: AppointmentStatus.canceled,
          ),
        ],
      );

      expect(find.text(AppStrings.homeTodayNothingLeftTitle), findsOneWidget);
      expect(find.text(AppStrings.homeTodayFinishedTitle), findsNothing);
      expect(find.text(AppStrings.homeTodayFinishedWarmLine), findsNothing);
      expect(find.text('1 atendimento cancelado'), findsOneWidget);
      expect(find.text(AppStrings.homeAgendaFreeToday), findsNothing);
    });

    testWidgets('U: semantics anuncia o dia encerrado', (tester) async {
      await pumpHome(tester, appointments: [completed('done', 9)]);

      expect(
        find.bySemanticsLabel(
          'Hoje. Tudo certo por hoje. 1 atendimento concluído.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('K: ícones decorativos não entram na árvore semântica', (
      tester,
    ) async {
      await pumpHome(tester, appointments: [completed('done', 9)]);

      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Hoje. Tudo certo por hoje. 1 atendimento concluído.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('estrela|coração|calendário')), findsNothing);
    });
  });

  group('comportamento preservado', () {
    testWidgets('O: tap no resumo continua abrindo a agenda de hoje', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => [upcoming('next', 16)],
          ),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
        ],
      );
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(appShellTabProvider), AppShellTab.home);

      await tester.tap(find.byKey(HomeTodaySummarySection.sectionKey));
      await tester.pumpAndSettle();

      expect(container.read(appShellTabProvider), AppShellTab.agenda);
      expect(
        find.bySemanticsLabel(AppStrings.homeOpenTodayAgendaLabel),
        findsOneWidget,
      );

      // O ticker vive no container: encerrar aqui evita Timer pendente.
      container.dispose();
    });

    testWidgets('V/W: renderizar e tickar não gera query extra', (tester) async {
      await pumpHome(
        tester,
        appointments: [completed('done', 9), upcoming('next', 16)],
      );

      expect(loads, 1);

      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(loads, 1);
      expect(find.text('2 atendimentos hoje'), findsOneWidget);
    });

    testWidgets('X/Y: Home rola e Ads seguem depois de Próximos Dias', (
      tester,
    ) async {
      await pumpHome(
        tester,
        appointments: [completed('done', 9)],
        upcomingDays: homeUpcomingThreeDays,
      );

      expect(find.byType(Scrollable), findsWidgets);

      final upcomingBottom = tester
          .getBottomLeft(find.byKey(HomeUpcomingDaysSection.sectionKey))
          .dy;
      final adTop = tester.getTopLeft(find.byKey(HomeAdSlot.slotKey)).dy;
      expect(adTop, greaterThanOrEqualTo(upcomingBottom));
    });
  });

  group('responsividade', () {
    const widths = [320.0, 360.0, 390.0, 430.0];
    const scales = [1.0, 1.3, 1.5];

    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('P/Q/R: ${width.toInt()}px textScale $scale sem overflow', (
          tester,
        ) async {
          for (final appointments in <List<AgendaAppointmentDisplay>>[
            const [],
            [upcoming('only', 16, 30)],
            [completed('done', 9)],
            [
              for (var index = 0; index < 10; index++)
                upcoming('apt-$index', 15, index),
            ],
          ]) {
            await pumpHome(
              tester,
              appointments: appointments,
              size: Size(width, 800),
              textScaler: TextScaler.linear(scale),
              upcomingDays: homeUpcomingThreeDays,
            );

            expectNoRenderOverflow(tester);
            expect(
              find.byKey(HomeTodaySummarySection.sectionKey),
              findsOneWidget,
            );
          }
        });
      }
    }

    testWidgets('F: 320px + textScale 1.5 continua sem overflow', (tester) async {
      await pumpHome(
        tester,
        appointments: [upcoming('only', 16, 30)],
        size: const Size(320, 800),
        textScaler: const TextScaler.linear(1.5),
      );

      expect(find.text('1 atendimento hoje'), findsOneWidget);
      expect(find.text('Próximo às 16:30'), findsOneWidget);
      expect(find.byKey(HomeTodaySummarySection.todayBadgeKey), findsOneWidget);
      expectNoRenderOverflow(tester);
    });
  });

  group('tipografia e alinhamento', () {
    const viewport390 = Size(390, 800);

    testWidgets('A/B: HOJE fica no topo, alinhado ao título', (tester) async {
      await pumpHome(
        tester,
        appointments: [completed('done', 9)],
        size: viewport390,
      );

      final badgeTop = tester
          .getTopLeft(find.byKey(HomeTodaySummarySection.todayBadgeKey))
          .dy;
      final titleTop = tester
          .getTopLeft(find.text(AppStrings.homeTodayFinishedTitle))
          .dy;
      final cardCenter = tester
          .getCenter(find.byKey(HomeTodaySummarySection.sectionKey))
          .dy;
      final badgeCenter = tester
          .getCenter(find.byKey(HomeTodaySummarySection.todayBadgeKey))
          .dy;

      expect(badgeTop, closeTo(titleTop, AppSpacing.xs));
      expect(badgeCenter, lessThan(cardCenter));
    });

    testWidgets('B: coluna central do card usa Expanded', (tester) async {
      await pumpHome(
        tester,
        appointments: [completed('done', 9)],
        size: viewport390,
      );

      expect(
        find.ancestor(
          of: find.text(AppStrings.homeTodayFinishedTitle),
          matching: find.byType(Expanded),
        ),
        findsOneWidget,
      );
    });

    void expectCardStateTitle(WidgetTester tester, String title) {
      final style = tester.widget<Text>(find.text(title)).style;
      expect(style?.fontSize, AppTypography.subtitle().fontSize);
      expect(style?.fontWeight, FontWeight.w800);
      expect(style?.color, AppColors.graphite);
    }

    void expectGreetingUsesTitleMedium(WidgetTester tester) {
      final greetingFinder = find.textContaining('Maria');
      final style = tester.widget<Text>(greetingFinder).style;
      expect(style?.fontSize, AppTheme.light.textTheme.titleMedium?.fontSize);
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.color, AppColors.graphite);
    }

    void expectCardTitleStrongerThanGreeting(WidgetTester tester, String title) {
      final cardStyle = tester.widget<Text>(find.text(title)).style;
      final greetingStyle = tester.widget<Text>(find.textContaining('Maria')).style;
      expect(
        cardStyle?.fontSize,
        greaterThan(greetingStyle?.fontSize ?? 0),
      );
      expect(
        cardStyle?.fontWeight?.value,
        greaterThanOrEqualTo(greetingStyle?.fontWeight?.value ?? 0),
      );
    }

    void expectTitleUsesAvailableWidth(WidgetTester tester, String title) {
      final titleWidth = tester.getSize(find.text(title)).width;
      final iconWidth = tester
          .getSize(find.byKey(HomeTodaySummarySection.stateIconKey))
          .width;
      expect(titleWidth, greaterThan(iconWidth));
    }

    testWidgets('C: título encerrado usa subtitle em 390px / 1.0', (
      tester,
    ) async {
      await pumpHome(
        tester,
        appointments: [completed('done', 9)],
        size: viewport390,
      );
      expectCardStateTitle(tester, AppStrings.homeTodayFinishedTitle);
      expectGreetingUsesTitleMedium(tester);
      expectCardTitleStrongerThanGreeting(
        tester,
        AppStrings.homeTodayFinishedTitle,
      );
      expectTitleUsesAvailableWidth(
        tester,
        AppStrings.homeTodayFinishedTitle,
      );
      expectNoRenderOverflow(tester);
    });

    testWidgets('D: título em andamento usa subtitle em 390px / 1.0', (
      tester,
    ) async {
      await pumpHome(
        tester,
        appointments: [upcoming('a', 16), upcoming('b', 17)],
        size: viewport390,
      );
      expectCardStateTitle(tester, '2 atendimentos hoje');
      expectTitleUsesAvailableWidth(tester, '2 atendimentos hoje');
      expectNoRenderOverflow(tester);
    });

    testWidgets('E: título dia livre usa subtitle em 390px / 1.0', (
      tester,
    ) async {
      await pumpHome(tester, appointments: const [], size: viewport390);
      expectCardStateTitle(tester, AppStrings.homeAgendaFreeToday);
      expectTitleUsesAvailableWidth(tester, AppStrings.homeAgendaFreeToday);
      expectNoRenderOverflow(tester);
    });

    testWidgets('F: ilustração maior em largura normal (390 / 1.0)', (
      tester,
    ) async {
      await pumpHome(
        tester,
        appointments: [completed('done', 9)],
        size: viewport390,
      );

      final iconSize = tester.getSize(
        find.byKey(HomeTodaySummarySection.stateIconKey),
      );
      expect(iconSize.width, HomeTodaySummarySection.illustrationSize);
      expect(iconSize.height, HomeTodaySummarySection.illustrationSize);
      expect(iconSize.width, greaterThan(56));
    });
  });
}
