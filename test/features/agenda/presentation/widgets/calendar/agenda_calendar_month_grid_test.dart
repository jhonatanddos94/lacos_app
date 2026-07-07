import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_month_grid.dart';

void main() {
  group('AgendaCalendarMonthGrid', () {
    test('fromDate usa o mês da data informada', () {
      final grid = AgendaCalendarMonthGrid.fromDate(DateTime(2026, 8, 20));

      expect(grid.year, 2026);
      expect(grid.month, 8);
      expect(grid.titleLabel, 'Agosto 2026');
    });

    test('buildCells retorna 42 dias em grade de 6 semanas', () {
      final grid = AgendaCalendarMonthGrid(year: 2026, month: 7);
      final cells = grid.buildCells();

      expect(cells.length, 42);
      expect(cells.where((cell) => cell.isCurrentMonth).length, 31);
    });

    test('julho de 2026 inicia com dias de junho na primeira semana', () {
      final grid = AgendaCalendarMonthGrid(year: 2026, month: 7);
      final cells = grid.buildCells();

      expect(cells.first.date, DateTime(2026, 6, 29));
      expect(cells.first.isCurrentMonth, isFalse);
      expect(cells[2].date, DateTime(2026, 7, 1));
      expect(cells[2].isCurrentMonth, isTrue);
    });

    test('previousMonth e nextMonth navegam corretamente', () {
      final grid = AgendaCalendarMonthGrid(year: 2026, month: 1);

      expect(grid.previousMonth().titleLabel, 'Dezembro 2025');
      expect(grid.nextMonth().titleLabel, 'Fevereiro 2026');
    });

    test('labels de navegação exibem nomes dos meses adjacentes', () {
      final grid = AgendaCalendarMonthGrid(year: 2026, month: 7);

      expect(grid.previousMonthLabel, 'Junho');
      expect(grid.nextMonthLabel, 'Agosto');
    });

    test('visibleDateRange cobre os 42 dias exibidos na grade', () {
      final grid = AgendaCalendarMonthGrid(year: 2026, month: 7);
      final range = grid.visibleDateRange();

      expect(range.start, DateTime(2026, 6, 29));
      expect(range.end, DateTime(2026, 8, 9));
    });
  });

  group('calendarDayHasAppointments', () {
    test('identifica dias normalizados no conjunto', () {
      final days = {
        DateTime(2026, 7, 14),
        DateTime(2026, 7, 17),
      };

      expect(
        calendarDayHasAppointments(DateTime(2026, 7, 14, 18), days),
        isTrue,
      );
      expect(
        calendarDayHasAppointments(DateTime(2026, 7, 16), days),
        isFalse,
      );
    });
  });

  group('isSameCalendarDay', () {
    test('compara apenas ano, mês e dia', () {
      expect(
        isSameCalendarDay(
          DateTime(2026, 9, 21, 14, 30),
          DateTime(2026, 9, 21, 8),
        ),
        isTrue,
      );
      expect(
        isSameCalendarDay(
          DateTime(2026, 9, 21),
          DateTime(2026, 9, 22),
        ),
        isFalse,
      );
    });
  });

  group('normalizeCalendarDay', () {
    test('remove componentes de hora', () {
      final normalized = normalizeCalendarDay(DateTime(2026, 9, 21, 18, 45));

      expect(normalized, DateTime(2026, 9, 21));
    });
  });
}
