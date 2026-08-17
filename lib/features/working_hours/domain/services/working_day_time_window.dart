import 'package:lacos_app/features/working_hours/domain/value_objects/working_day_availability.dart';

/// Converte minutos desde meia-noite em [DateTime] na data informada.
abstract final class WorkingDayTimeWindow {
  static DateTime timeOnDay(DateTime day, int minutesFromMidnight) {
    return DateTime(
      day.year,
      day.month,
      day.day,
      minutesFromMidnight ~/ 60,
      minutesFromMidnight % 60,
    );
  }
}

extension WorkingDayAvailabilityTimeWindow on WorkingDayAvailability {
  DateTime openingTimeOn(DateTime day) {
    return WorkingDayTimeWindow.timeOnDay(day, startMinutes);
  }

  DateTime closingTimeOn(DateTime day) {
    return WorkingDayTimeWindow.timeOnDay(day, endMinutes);
  }
}
