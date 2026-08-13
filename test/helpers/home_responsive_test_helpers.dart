import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_upcoming_days_section.dart';

/// Viewport compacto equivalente a dispositivo estreito.
const homeCompactViewport = Size(320, 640);

final homeUpcomingThreeDays = [
  HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 4),
  HomeUpcomingDay(day: DateTime(2026, 8, 15), appointmentCount: 2),
  HomeUpcomingDay(day: DateTime(2026, 8, 17), appointmentCount: 6),
];

final homeUpcomingStressDays = [
  HomeUpcomingDay(day: DateTime(2026, 8, 14), appointmentCount: 1),
  HomeUpcomingDay(day: DateTime(2026, 9, 30), appointmentCount: 128),
  HomeUpcomingDay(day: DateTime(2026, 12, 31), appointmentCount: 1),
];

Future<void> configureCompactViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(homeCompactViewport);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget wrapTextScale({
  required TextScaler textScaler,
  required Widget child,
}) {
  return MediaQuery(
    data: MediaQueryData(
      textScaler: textScaler,
      size: homeCompactViewport,
    ),
    child: child,
  );
}

/// Espelha o uso real na Home: conteúdo dentro de área rolável.
Widget buildScrollableUpcomingSection({
  required List<HomeUpcomingDay> days,
  required DateTime today,
  required TextScaler textScaler,
}) {
  return wrapTextScale(
    textScaler: textScaler,
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: HomeUpcomingDaysSection(
            days: days,
            today: today,
            onOpenAgenda: () {},
            onOpenDay: (_) {},
          ),
        ),
      ),
    ),
  );
}

void expectNoRenderOverflow(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

Future<void> scrollHomeToVisible(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
