import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_availability_calculator.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_day_time_window.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_hours_resolver.dart';
import 'package:lacos_app/features/working_hours/domain/value_objects/working_day_availability.dart';

import '../../../../helpers/appointment_schedule_test_support.dart';

void main() {
  const calculator = AppointmentAvailabilityCalculator();
  const engine = AvailabilityEngine();

  group('AppointmentAvailabilityCalculator + WorkingHours', () {
    test('A: fallback 09–18 sem config persistida', () {
      final day = DateTime(2030, 6, 3);
      final availability = WorkingHoursResolver.resolve(
        day: day,
        configuredWeek: const [],
      );

      final slots = calculator.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        dayAppointments: const [],
        professionalId: appointmentTestProfessionalId,
        dayAvailability: availability,
      );

      expect(slots.first, DateTime(2030, 6, 3, 9));
      expect(slots.last, DateTime(2030, 6, 3, 17));
    });

    test('B: custom 07–20', () {
      final monday = DateTime(2030, 6, 3);
      final availability = WorkingHoursResolver.resolve(
        day: monday,
        configuredWeek: workingWeek(
          salonId: appointmentTestSalonId,
          professionalId: appointmentTestProfessionalId,
          weekday: DateTime.monday,
          isWorking: true,
          startMinutes: 7 * 60,
          endMinutes: 20 * 60,
        ),
      );

      final slots = calculator.calculateAvailableStartTimes(
        day: monday,
        durationMinutes: 60,
        dayAppointments: const [],
        professionalId: appointmentTestProfessionalId,
        dayAvailability: availability,
      );

      expect(slots.first, DateTime(2030, 6, 3, 7));
      expect(slots.last, DateTime(2030, 6, 3, 19));
    });

    test('C: custom 10–16', () {
      final day = DateTime(2030, 6, 4);
      final availability = WorkingHoursResolver.resolve(
        day: day,
        configuredWeek: workingWeek(
          salonId: appointmentTestSalonId,
          professionalId: appointmentTestProfessionalId,
          weekday: DateTime.tuesday,
          isWorking: true,
          startMinutes: 10 * 60,
          endMinutes: 16 * 60,
        ),
      );

      final slots = calculator.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        dayAppointments: const [],
        professionalId: appointmentTestProfessionalId,
        dayAvailability: availability,
      );

      expect(slots.first, DateTime(2030, 6, 4, 10));
      expect(slots.last, DateTime(2030, 6, 4, 15));
    });

    test('D: domingo ativo 10–16', () {
      final sunday = DateTime(2030, 6, 2);
      final availability = WorkingHoursResolver.resolve(
        day: sunday,
        configuredWeek: workingWeek(
          salonId: appointmentTestSalonId,
          professionalId: appointmentTestProfessionalId,
          weekday: DateTime.sunday,
          isWorking: true,
          startMinutes: 10 * 60,
          endMinutes: 16 * 60,
        ),
      );

      expect(availability.isWorking, isTrue);
      expect(
        calculator.calculateAvailableStartTimes(
          day: sunday,
          durationMinutes: 60,
          dayAppointments: const [],
          professionalId: appointmentTestProfessionalId,
          dayAvailability: availability,
        ),
        isNotEmpty,
      );
    });

    test('E: domingo fechado não gera slots', () {
      final sunday = DateTime(2030, 6, 2);
      final availability = WorkingHoursResolver.resolve(
        day: sunday,
        configuredWeek: workingWeek(
          salonId: appointmentTestSalonId,
          professionalId: appointmentTestProfessionalId,
          weekday: DateTime.sunday,
          isWorking: false,
        ),
      );

      final slots = calculator.calculateAvailableStartTimes(
        day: sunday,
        durationMinutes: 60,
        dayAppointments: const [],
        professionalId: appointmentTestProfessionalId,
        dayAvailability: availability,
      );

      expect(slots, isEmpty);
    });

    test('F: weekday ausente usa fallback', () {
      final wednesday = DateTime(2030, 6, 5);
      final availability = WorkingHoursResolver.resolve(
        day: wednesday,
        configuredWeek: workingWeek(
          salonId: appointmentTestSalonId,
          professionalId: appointmentTestProfessionalId,
          weekday: DateTime.monday,
          isWorking: true,
          startMinutes: 7 * 60,
          endMinutes: 20 * 60,
        ),
      );

      expect(availability.startMinutes, 9 * 60);
      expect(availability.endMinutes, 18 * 60);
    });

    test('G/H: serviço termina no closing e ultrapassar é inválido', () {
      final day = DateTime(2030, 6, 3);
      final availability = WorkingDayAvailability.working(
        startMinutes: 7 * 60,
        endMinutes: 20 * 60,
      );
      final opening = availability.openingTimeOn(day);
      final closing = availability.closingTimeOn(day);

      expect(
        engine.isIntervalAvailable(
          startAt: DateTime(2030, 6, 3, 19),
          endAt: DateTime(2030, 6, 3, 20),
          professionalId: appointmentTestProfessionalId,
          existingAppointments: const [],
          openingTime: opening,
          closingTime: closing,
        ),
        isTrue,
      );

      expect(
        engine.isIntervalAvailable(
          startAt: DateTime(2030, 6, 3, 19, 15),
          endAt: DateTime(2030, 6, 3, 20, 15),
          professionalId: appointmentTestProfessionalId,
          existingAppointments: const [],
          openingTime: opening,
          closingTime: closing,
        ),
        isFalse,
      );
    });

    test('J: último slot respeita duração longa', () {
      final day = DateTime(2030, 6, 3);
      final availability = WorkingDayAvailability.working(
        startMinutes: 7 * 60,
        endMinutes: 20 * 60,
      );

      final slots = calculator.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 180,
        dayAppointments: const [],
        professionalId: appointmentTestProfessionalId,
        dayAvailability: availability,
      );

      expect(slots.last, DateTime(2030, 6, 3, 17));
      expect(slots.any((slot) => slot.hour == 17 && slot.minute == 15), isFalse);
    });

    test('K/L/M: conflitos e canceled preservados', () {
      final day = DateTime(2030, 6, 3);
      final availability = WorkingDayAvailability.working(
        startMinutes: 7 * 60,
        endMinutes: 20 * 60,
      );
      final opening = availability.openingTimeOn(day);
      final closing = availability.closingTimeOn(day);
      final blocking = _appointment(
        start: DateTime(2030, 6, 3, 10),
        end: DateTime(2030, 6, 3, 11),
      );

      expect(
        engine.isIntervalAvailable(
          startAt: DateTime(2030, 6, 3, 10),
          endAt: DateTime(2030, 6, 3, 11),
          professionalId: appointmentTestProfessionalId,
          existingAppointments: [blocking],
          openingTime: opening,
          closingTime: closing,
        ),
        isFalse,
      );

      expect(
        engine.isIntervalAvailable(
          startAt: DateTime(2030, 6, 3, 10),
          endAt: DateTime(2030, 6, 3, 11),
          professionalId: 'professional-b',
          existingAppointments: [blocking],
          openingTime: opening,
          closingTime: closing,
        ),
        isTrue,
      );

      expect(
        engine.isIntervalAvailable(
          startAt: DateTime(2030, 6, 3, 10),
          endAt: DateTime(2030, 6, 3, 11),
          professionalId: appointmentTestProfessionalId,
          existingAppointments: [
            _appointment(
              start: DateTime(2030, 6, 3, 10),
              end: DateTime(2030, 6, 3, 11),
              status: AppointmentStatus.canceled,
            ),
          ],
          openingTime: opening,
          closingTime: closing,
        ),
        isTrue,
      );
    });

    test('O: dia fechado não chama engine com janela fake', () {
      final availability = WorkingDayAvailability.closed();
      final slots = calculator.calculateAvailableStartTimes(
        day: DateTime(2030, 6, 2),
        durationMinutes: 60,
        dayAppointments: const [],
        professionalId: appointmentTestProfessionalId,
        dayAvailability: availability,
      );

      expect(slots, isEmpty);
    });
  });
}

Appointment _appointment({
  required DateTime start,
  required DateTime end,
  AppointmentStatus status = AppointmentStatus.confirmed,
  String professionalId = 'professional-1',
}) {
  final now = DateTime(2030, 6, 1);

  return Appointment(
    id: 'appointment-1',
    salonId: appointmentTestSalonId,
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: professionalId,
    startAt: start,
    endAt: end,
    status: status,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
