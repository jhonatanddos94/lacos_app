import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/appointments/domain/scheduling/scheduling_defaults.dart';
import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';

abstract final class WorkingHoursValidator {
  static const _minutesInDay = 24 * 60;

  static String? validateWeekday(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      return AppValidationMessages.workingHoursInvalidWeekday;
    }
    return null;
  }

  static String? validateDay(ProfessionalWorkingHours day) {
    final weekdayError = validateWeekday(day.weekday);
    if (weekdayError != null) {
      return weekdayError;
    }

    if (!day.isWorking) {
      return null;
    }

    if (!_isAlignedToSlot(day.startMinutes) || !_isAlignedToSlot(day.endMinutes)) {
      return AppValidationMessages.workingHoursInvalidGranularity;
    }

    if (day.startMinutes < 0 || day.endMinutes > _minutesInDay) {
      return AppValidationMessages.workingHoursOutOfRange;
    }

    if (day.startMinutes >= day.endMinutes) {
      return AppValidationMessages.workingHoursInvalidRange;
    }

    if (day.endMinutes - day.startMinutes <
        SchedulingDefaults.slotIntervalMinutes) {
      return AppValidationMessages.workingHoursDurationTooShort;
    }

    return null;
  }

  static String? validateWeek(List<ProfessionalWorkingHours> week) {
    if (week.length != DateTime.daysPerWeek) {
      return AppValidationMessages.workingHoursIncompleteWeek;
    }

    final weekdays = week.map((day) => day.weekday).toSet();
    if (weekdays.length != DateTime.daysPerWeek) {
      return AppValidationMessages.workingHoursDuplicateWeekday;
    }

    for (final day in week) {
      final error = validateDay(day);
      if (error != null) {
        return error;
      }
    }

    return null;
  }

  static bool _isAlignedToSlot(int minutes) {
    return minutes % SchedulingDefaults.slotIntervalMinutes == 0;
  }
}
