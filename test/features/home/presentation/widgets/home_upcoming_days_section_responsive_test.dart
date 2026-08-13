import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/services/home_upcoming_days_formatter.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';

import '../../../../helpers/home_responsive_test_helpers.dart';

void main() {
  final today = DateTime(2026, 8, 13);

  group('HomeUpcomingDaysSection responsividade', () {
    Future<void> pumpSection(
      WidgetTester tester, {
      required TextScaler textScaler,
      required List<HomeUpcomingDay> days,
    }) async {
      await configureCompactViewport(tester);
      await tester.pumpWidget(
        buildScrollableUpcomingSection(
          days: days,
          today: today,
          textScaler: textScaler,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('A) 320px textScale 1.0 com 3 dias', (tester) async {
      await pumpSection(
        tester,
        textScaler: TextScaler.noScaling,
        days: homeUpcomingThreeDays,
      );
      expectNoRenderOverflow(tester);
    });

    testWidgets('B) 320px textScale 1.3 com 3 dias', (tester) async {
      await pumpSection(
        tester,
        textScaler: TextScaler.linear(1.3),
        days: homeUpcomingThreeDays,
      );
      expectNoRenderOverflow(tester);
    });

    testWidgets('C) 320px textScale 1.5 com 3 dias', (tester) async {
      await pumpSection(
        tester,
        textScaler: TextScaler.linear(1.5),
        days: homeUpcomingThreeDays,
      );
      expectNoRenderOverflow(tester);
    });

    testWidgets('D) largura normal textScale 1.3 com 3 dias', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapTextScale(
          textScaler: TextScaler.linear(1.3),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeUpcomingDaysSection(
                  days: homeUpcomingThreeDays,
                  today: today,
                  onOpenAgenda: () {},
                  onOpenDay: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expectNoRenderOverflow(tester);
    });

    testWidgets('E) data longa Quarta, 30 set.', (tester) async {
      await pumpSection(
        tester,
        textScaler: TextScaler.linear(1.3),
        days: [
          HomeUpcomingDay(day: DateTime(2026, 9, 30), appointmentCount: 1),
        ],
      );

      expect(find.text('Quarta, 30 set.'), findsOneWidget);
      expectNoRenderOverflow(tester);
    });

    testWidgets('F) contagem 128 atendimentos', (tester) async {
      await pumpSection(
        tester,
        textScaler: TextScaler.linear(1.3),
        days: [
          HomeUpcomingDay(day: DateTime(2026, 9, 30), appointmentCount: 128),
        ],
      );

      expect(find.text('128 ${AppStrings.homeAppointmentPlural}'), findsOneWidget);
      expectNoRenderOverflow(tester);
    });

    testWidgets('G) virada de ano Quinta, 31 dez.', (tester) async {
      await pumpSection(
        tester,
        textScaler: TextScaler.linear(1.3),
        days: [
          HomeUpcomingDay(day: DateTime(2026, 12, 31), appointmentCount: 1),
        ],
      );

      expect(find.text('Quinta, 31 dez.'), findsOneWidget);
      expectNoRenderOverflow(tester);
    });

    testWidgets('H) header + 3 linhas + Ver agenda', (tester) async {
      await pumpSection(
        tester,
        textScaler: TextScaler.linear(1.3),
        days: homeUpcomingThreeDays,
      );

      expect(find.text(AppStrings.homeUpcomingDaysTitle), findsOneWidget);
      expect(find.text(AppStrings.homeUpcomingDaysOpenAgenda), findsOneWidget);
      expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsOneWidget);
      expectNoRenderOverflow(tester);
    });
  });

  group('comportamento preservado', () {
    testWidgets('linha inteira é clicável', (tester) async {
      DateTime? openedDay;

      await configureCompactViewport(tester);
      await tester.pumpWidget(
        wrapTextScale(
          textScaler: TextScaler.linear(1.3),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeUpcomingDaysSection(
                  days: [
                    HomeUpcomingDay(
                      day: DateTime(2026, 8, 14),
                      appointmentCount: 1,
                    ),
                  ],
                  today: today,
                  onOpenAgenda: () {},
                  onOpenDay: (day) => openedDay = day,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 14))),
      );
      await tester.pump();

      expect(openedDay, DateTime(2026, 8, 14));
    });

    testWidgets('Semantics preservada em textScale 1.3', (tester) async {
      await configureCompactViewport(tester);
      await tester.pumpWidget(
        buildScrollableUpcomingSection(
          days: [HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 1)],
          today: today,
          textScaler: TextScaler.linear(1.3),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(
          find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 14))),
        ),
        matchesSemantics(
          label: HomeUpcomingDaysFormatter.formatSemanticsLabel(
            day: DateTime(2026, 8, 14),
            today: today,
            count: 1,
          ),
          isButton: true,
        ),
      );
    });
  });
}
