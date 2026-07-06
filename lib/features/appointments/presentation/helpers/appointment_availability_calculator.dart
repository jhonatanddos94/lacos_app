import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';

class AppointmentAvailabilityCalculator {
  const AppointmentAvailabilityCalculator({
    AvailabilityEngine? engine,
  }) : _engine = engine ?? const AvailabilityEngine();

  // TODO: futuro: substituir por horário de funcionamento do salão.
  static const salonOpeningHour = 9;
  static const salonClosingHour = 18;
  static const maxDisplayedStartTimes = 8;

  final AvailabilityEngine _engine;

  List<DateTime> calculateAvailableStartTimes({
    required DateTime day,
    required int durationMinutes,
    required List<Appointment> dayAppointments,
    required String professionalId,
  }) {
    final professionalAppointments = dayAppointments
        .where((appointment) => appointment.professionalId == professionalId)
        .toList(growable: false);

    final normalizedDay = DateTime(day.year, day.month, day.day);
    final openingTime = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      salonOpeningHour,
    );
    final closingTime = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      salonClosingHour,
    );

    return _engine.calculateAvailableStartTimes(
      day: normalizedDay,
      durationMinutes: durationMinutes,
      existingAppointments: professionalAppointments,
      openingTime: openingTime,
      closingTime: closingTime,
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
