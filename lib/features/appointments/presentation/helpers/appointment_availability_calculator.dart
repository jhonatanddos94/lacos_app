import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_day_time_window.dart';
import 'package:lacos_app/features/working_hours/domain/value_objects/working_day_availability.dart';

class AppointmentAvailabilityCalculator {
  const AppointmentAvailabilityCalculator({AvailabilityEngine? engine})
    : _engine = engine ?? const AvailabilityEngine();

  static const maxDisplayedStartTimes = 8;

  final AvailabilityEngine _engine;

  List<DateTime> calculateAvailableStartTimes({
    required DateTime day,
    required int durationMinutes,
    required List<Appointment> dayAppointments,
    required String professionalId,
    required WorkingDayAvailability dayAvailability,
  }) {
    if (!dayAvailability.isWorking) {
      return const [];
    }

    final professionalAppointments = dayAppointments
        .where((appointment) => appointment.professionalId == professionalId)
        .toList(growable: false);

    final normalizedDay = DateTime(day.year, day.month, day.day);
    final openingTime = dayAvailability.openingTimeOn(normalizedDay);
    final closingTime = dayAvailability.closingTimeOn(normalizedDay);

    DateTime? notBefore;
    final now = DateTime.now();
    if (isSameAppointmentDate(normalizedDay, now)) {
      notBefore = now;
    }

    return _engine.calculateAvailableStartTimes(
      day: normalizedDay,
      durationMinutes: durationMinutes,
      existingAppointments: professionalAppointments,
      openingTime: openingTime,
      closingTime: closingTime,
      notBefore: notBefore,
    );
  }

  List<int> toDisplayedStartTimeMinutes(List<DateTime> availableStartTimes) {
    return availableStartTimes
        .take(maxDisplayedStartTimes)
        .map(toMinutesFromMidnight)
        .toList(growable: false);
  }

  static int toMinutesFromMidnight(DateTime dateTime) {
    return dateTime.hour * 60 + dateTime.minute;
  }

  static bool isStartTimeAvailable({
    required int startTimeMinutes,
    required List<DateTime> availableStartTimes,
  }) {
    return availableStartTimes.any(
      (time) => toMinutesFromMidnight(time) == startTimeMinutes,
    );
  }
}
