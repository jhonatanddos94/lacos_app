import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/services/home_upcoming_days_formatter.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';

import '../../../../helpers/home_responsive_test_helpers.dart';

void main() {
  final today = DateTime(2026, 8, 13);

  Widget buildSection({
    required List<HomeUpcomingDay> days,
    VoidCallback? onOpenAgenda,
    ValueChanged<DateTime>? onOpenDay,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeUpcomingDaysSection(
          days: days,
          today: today,
          onOpenAgenda: onOpenAgenda ?? () {},
          onOpenDay: onOpenDay ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('empty esconde seção', (tester) async {
    await tester.pumpWidget(buildSection(days: const []));

    expect(find.byKey(HomeUpcomingDaysSection.sectionKey), findsNothing);
  });

  testWidgets('1 linha', (tester) async {
    await tester.pumpWidget(
      buildSection(
        days: [
          HomeUpcomingDay(
            day: DateTime(2026, 8, 14),
            appointmentCount: 4,
          ),
        ],
      ),
    );

    expect(find.text(AppStrings.appointmentDateTomorrow), findsOneWidget);
    expect(find.text('4 ${AppStrings.homeAppointmentPlural}'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('3 linhas', (tester) async {
    await tester.pumpWidget(
      buildSection(
        days: [
          HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 4),
          HomeUpcomingDay(day: DateTime(2026, 8, 15), appointmentCount: 2),
          HomeUpcomingDay(day: DateTime(2026, 8, 17), appointmentCount: 6),
        ],
      ),
    );

    expect(find.text(AppStrings.appointmentDateTomorrow), findsOneWidget);
    expect(find.text('Sábado, 15 ago.'), findsOneWidget);
    expect(find.text('Segunda, 17 ago.'), findsOneWidget);
  });

  testWidgets('linha inteira é clicável', (tester) async {
    DateTime? openedDay;

    await tester.pumpWidget(
      buildSection(
        days: [
          HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 1),
        ],
        onOpenDay: (day) => openedDay = day,
      ),
    );

    await tester.tap(find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 14))));
    await tester.pump();

    expect(openedDay, DateTime(2026, 8, 14));
  });

  testWidgets('Semantics correta', (tester) async {
    await tester.pumpWidget(
      buildSection(
        days: [
          HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 1),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.byKey(HomeUpcomingDaysSection.rowKey(DateTime(2026, 8, 14)))),
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

  testWidgets('Ver agenda dispara callback', (tester) async {
    var opened = false;

    await tester.pumpWidget(
      buildSection(
        days: [
          HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 1),
        ],
        onOpenAgenda: () => opened = true,
      ),
    );

    await tester.tap(find.byKey(HomeUpcomingDaysSection.openAgendaKey));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('320px sem overflow', (tester) async {
    await configureCompactViewport(tester);

    await tester.pumpWidget(
      buildScrollableUpcomingSection(
        days: [
          HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 12),
          HomeUpcomingDay(day: DateTime(2026, 8, 15), appointmentCount: 2),
          HomeUpcomingDay(day: DateTime(2026, 8, 17), appointmentCount: 6),
        ],
        today: today,
        textScaler: TextScaler.noScaling,
      ),
    );
    await tester.pumpAndSettle();

    expectNoRenderOverflow(tester);
  });

  testWidgets('textScale 1.3 com 3 linhas sem overflow', (tester) async {
    await configureCompactViewport(tester);

    await tester.pumpWidget(
      buildScrollableUpcomingSection(
        days: [
          HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 12),
          HomeUpcomingDay(day: DateTime(2026, 8, 15), appointmentCount: 2),
          HomeUpcomingDay(day: DateTime(2026, 8, 17), appointmentCount: 6),
        ],
        today: today,
        textScaler: TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();

    expectNoRenderOverflow(tester);
  });
}
