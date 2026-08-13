import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/home/application/services/home_upcoming_days_formatter.dart';

void main() {
  final today = DateTime(2026, 8, 13);

  group('HomeUpcomingDaysFormatter.formatSemanticsLabel', () {
    test('Amanhã, 1 atendimento. Abrir agenda.', () {
      expect(
        HomeUpcomingDaysFormatter.formatSemanticsLabel(
          day: DateTime(2026, 8, 14),
          today: today,
          count: 1,
        ),
        'Amanhã, 1 atendimento. Abrir agenda.',
      );
    });

    test('Sábado, 15 de agosto, 2 atendimentos. Abrir agenda.', () {
      expect(
        HomeUpcomingDaysFormatter.formatSemanticsLabel(
          day: DateTime(2026, 8, 15),
          today: today,
          count: 2,
        ),
        'Sábado, 15 de Agosto, 2 atendimentos. Abrir agenda.',
      );
    });
  });
}
