import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_day_status.dart';

void main() {
  group('agenda day status', () {
    test('isPastAgendaDay retorna true para dias anteriores a hoje', () {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);

      expect(isPastAgendaDay(yesterday), isTrue);
      expect(isOperationalAgendaDay(yesterday), isFalse);
    });

    test('isOperationalAgendaDay retorna true para hoje e futuro', () {
      final today = DateTime.now();
      final tomorrow = DateTime(today.year, today.month, today.day + 1);

      expect(isPastAgendaDay(today), isFalse);
      expect(isOperationalAgendaDay(today), isTrue);
      expect(isPastAgendaDay(tomorrow), isFalse);
      expect(isOperationalAgendaDay(tomorrow), isTrue);
    });
  });
}
