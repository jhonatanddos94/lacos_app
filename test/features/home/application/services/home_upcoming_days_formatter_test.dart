import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/home/application/services/home_upcoming_days_formatter.dart';

void main() {
  final today = DateTime(2026, 8, 13);

  group('HomeUpcomingDaysFormatter.formatDayLabel', () {
    test('Amanhã', () {
      expect(
        HomeUpcomingDaysFormatter.formatDayLabel(
          day: DateTime(2026, 8, 14),
          today: today,
        ),
        AppStrings.appointmentDateTomorrow,
      );
    });

    test('Sábado, 15 ago.', () {
      expect(
        HomeUpcomingDaysFormatter.formatDayLabel(
          day: DateTime(2026, 8, 15),
          today: today,
        ),
        'Sábado, 15 ago.',
      );
    });

    test('Segunda, 17 ago.', () {
      expect(
        HomeUpcomingDaysFormatter.formatDayLabel(
          day: DateTime(2026, 8, 17),
          today: today,
        ),
        'Segunda, 17 ago.',
      );
    });

    test('virada de mês', () {
      expect(
        HomeUpcomingDaysFormatter.formatDayLabel(
          day: DateTime(2026, 8, 31),
          today: DateTime(2026, 8, 13),
        ),
        'Segunda, 31 ago.',
      );
    });

    test('virada de ano', () {
      expect(
        HomeUpcomingDaysFormatter.formatDayLabel(
          day: DateTime(2027, 1, 2),
          today: DateTime(2026, 12, 31),
        ),
        'Sábado, 2 jan.',
      );
    });
  });

  group('HomeUpcomingDaysFormatter.formatCountLabel', () {
    test('1 atendimento', () {
      expect(
        HomeUpcomingDaysFormatter.formatCountLabel(1),
        '1 ${AppStrings.homeAppointmentSingular}',
      );
    });

    test('2 atendimentos', () {
      expect(
        HomeUpcomingDaysFormatter.formatCountLabel(2),
        '2 ${AppStrings.homeAppointmentPlural}',
      );
    });
  });
}
