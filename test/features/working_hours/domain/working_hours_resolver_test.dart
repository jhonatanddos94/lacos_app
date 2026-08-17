import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/scheduling/scheduling_defaults.dart';
import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_hours_resolver.dart';
import 'package:lacos_app/features/working_hours/domain/value_objects/working_day_availability.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  ProfessionalWorkingHours entry({
    required int weekday,
    bool isWorking = true,
    int startMinutes = 7 * 60,
    int endMinutes = 20 * 60,
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

  group('WorkingHoursResolver', () {
    test('A: sem config retorna 09:00–18:00', () {
      final availability = WorkingHoursResolver.resolve(
        day: DateTime(2026, 3, 10),
        configuredWeek: const [],
      );

      expect(availability, WorkingDayAvailability.fromDefaults());
      expect(availability.isWorking, isTrue);
      expect(availability.startMinutes, SchedulingDefaults.openingMinutes);
      expect(availability.endMinutes, SchedulingDefaults.closingMinutes);
    });

    test('B: segunda configurada retorna valor salvo', () {
      final availability = WorkingHoursResolver.resolve(
        day: DateTime(2026, 3, 9),
        configuredWeek: [entry(weekday: DateTime.monday)],
      );

      expect(availability.isWorking, isTrue);
      expect(availability.startMinutes, 7 * 60);
      expect(availability.endMinutes, 20 * 60);
    });

    test('C/D: domingo configurado pode estar ativo', () {
      final availability = WorkingHoursResolver.resolve(
        day: DateTime(2026, 3, 15),
        configuredWeek: [
          entry(
            weekday: DateTime.sunday,
            startMinutes: 10 * 60,
            endMinutes: 16 * 60,
          ),
        ],
      );

      expect(availability.isWorking, isTrue);
      expect(availability.startMinutes, 10 * 60);
      expect(availability.endMinutes, 16 * 60);
    });

    test('E: domingo configurado pode estar inativo', () {
      final availability = WorkingHoursResolver.resolve(
        day: DateTime(2026, 3, 15),
        configuredWeek: [
          entry(weekday: DateTime.sunday, isWorking: false),
        ],
      );

      expect(availability.isWorking, isFalse);
    });
  });
}
