import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

class AppointmentPreparationEligibility {
  const AppointmentPreparationEligibility._();

  static bool isEligible({
    required AppointmentStatus status,
    required DateTime startAt,
    required DateTime endAt,
    required DateTime now,
    Duration beforeStartWindow = AppDurations.appointmentPreparationBeforeStart,
  }) {
    if (status == AppointmentStatus.completed ||
        status == AppointmentStatus.canceled) {
      return false;
    }

    final today = normalizeAppointmentDate(now);
    final appointmentDay = normalizeAppointmentDate(startAt);
    if (appointmentDay != today) {
      return false;
    }

    final windowStart = startAt.subtract(beforeStartWindow);
    return !now.isBefore(windowStart);
  }
}
