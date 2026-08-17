import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_hours_validator.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  ProfessionalWorkingHours day({
    required int weekday,
    bool isWorking = true,
    int startMinutes = 9 * 60,
    int endMinutes = 18 * 60,
  }) {
    return ProfessionalWorkingHours(
      id: 'wh-$weekday',
      salonId: 'salon-1',
      professionalId: 'pro-1',
      weekday: weekday,
      isWorking: isWorking,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<ProfessionalWorkingHours> fullWeek() {
    return [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        day(weekday: weekday),
    ];
  }

  group('WorkingHoursValidator', () {
    test('F: aceita weekday 1..7', () {
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
        expect(WorkingHoursValidator.validateWeekday(weekday), isNull);
      }
    });

    test('G: start < end', () {
      expect(
        WorkingHoursValidator.validateDay(
          day(weekday: DateTime.monday, startMinutes: 18 * 60, endMinutes: 9 * 60),
        ),
        AppValidationMessages.workingHoursInvalidRange,
      );
    });

    test('H: start == end inválido', () {
      expect(
        WorkingHoursValidator.validateDay(
          day(weekday: DateTime.monday, startMinutes: 9 * 60, endMinutes: 9 * 60),
        ),
        AppValidationMessages.workingHoursInvalidRange,
      );
    });

    test('I: start > end inválido', () {
      expect(
        WorkingHoursValidator.validateDay(
          day(weekday: DateTime.monday, startMinutes: 12 * 60, endMinutes: 11 * 60),
        ),
        AppValidationMessages.workingHoursInvalidRange,
      );
    });

    test('J: granularidade 15 min', () {
      expect(
        WorkingHoursValidator.validateDay(
          day(weekday: DateTime.monday, startMinutes: 9 * 60 + 7),
        ),
        AppValidationMessages.workingHoursInvalidGranularity,
      );
    });

    test('semana completa válida', () {
      expect(WorkingHoursValidator.validateWeek(fullWeek()), isNull);
    });

    test('domingo inativo ignora horários', () {
      expect(
        WorkingHoursValidator.validateDay(
          day(
            weekday: DateTime.sunday,
            isWorking: false,
            startMinutes: 18 * 60,
            endMinutes: 9 * 60,
          ),
        ),
        isNull,
      );
    });
  });
}
