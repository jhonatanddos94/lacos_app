import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_relative_time_formatter.dart';

void main() {
  group('AppointmentRelativeTimeFormatter', () {
    const formatter = AppointmentRelativeTimeFormatter();

    test('formata 15 minutos', () {
      expect(
        formatter.formatSince(
          reference: DateTime(2026, 7, 8, 10),
          now: DateTime(2026, 7, 8, 10, 15),
        ),
        'há 15 minutos',
      );
    });

    test('formata 1 hora', () {
      expect(
        formatter.formatSince(
          reference: DateTime(2026, 7, 8, 10),
          now: DateTime(2026, 7, 8, 11),
        ),
        'há 1h',
      );
    });

    test('formata 2h30', () {
      expect(
        formatter.formatSince(
          reference: DateTime(2026, 7, 8, 10),
          now: DateTime(2026, 7, 8, 12, 30),
        ),
        'há 2h 30min',
      );
    });

    test('formata 1 dia', () {
      expect(
        formatter.formatSince(
          reference: DateTime(2026, 7, 7, 10),
          now: DateTime(2026, 7, 8, 10),
        ),
        'há 1 dia',
      );
    });

    test('monta texto complementar de overdue', () {
      expect(
        formatter.formatOverdueWaitingSince(
          endAt: DateTime(2026, 7, 8, 10),
          now: DateTime(2026, 7, 8, 10, 35),
        ),
        '${AppStrings.appointmentOperationalOverdueRelativePrefix} há 35 minutos',
      );
    });
  });
}
