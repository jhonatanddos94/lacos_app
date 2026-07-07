import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/appointments/presentation/appointment_form_mode.dart';

DateTime? resolveAppointmentFormInitialSelectedDate({
  required AppointmentFormMode mode,
  DateTime? initialDate,
  DateTime? existingAppointmentStartAt,
}) {
  if (mode == AppointmentFormMode.edit) {
    if (existingAppointmentStartAt == null) {
      return null;
    }

    return normalizeAppointmentDate(existingAppointmentStartAt);
  }

  if (initialDate == null) {
    return null;
  }

  return normalizeAppointmentDate(initialDate);
}
