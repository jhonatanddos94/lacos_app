import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/time/app_clock.dart';

void main() {
  group('durationUntilNextLocalMidnight', () {
    test('calcula o intervalo até 00:00 local', () {
      final now = DateTime(2026, 8, 13, 23, 59, 0);

      expect(durationUntilNextLocalMidnight(now), const Duration(minutes: 1));
    });

    test('usa data local e não UTC', () {
      final now = DateTime(2026, 8, 13, 22, 0);

      expect(durationUntilNextLocalMidnight(now), const Duration(hours: 2));
    });

    test('em meia-noite aponta para o próximo dia', () {
      final now = DateTime(2026, 8, 13);

      expect(durationUntilNextLocalMidnight(now), const Duration(days: 1));
    });
  });
}
