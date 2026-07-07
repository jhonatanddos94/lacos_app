import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/appointments/presentation/appointment_form_mode.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_form_initial_date.dart';

void main() {
  group('resolveAppointmentFormInitialSelectedDate', () {
    test('create com initialDate usa a data informada', () {
      final initialDate = DateTime(2026, 7, 10, 15, 30);

      final result = resolveAppointmentFormInitialSelectedDate(
        mode: AppointmentFormMode.create,
        initialDate: initialDate,
      );

      expect(result, DateTime(2026, 7, 10));
    });

    test('create sem initialDate mantém null', () {
      final result = resolveAppointmentFormInitialSelectedDate(
        mode: AppointmentFormMode.create,
      );

      expect(result, isNull);
    });

    test('edit ignora initialDate e usa data do appointment', () {
      final appointmentStartAt = DateTime(2026, 7, 12, 9);
      final agendaDate = DateTime(2026, 7, 10);

      final result = resolveAppointmentFormInitialSelectedDate(
        mode: AppointmentFormMode.edit,
        initialDate: agendaDate,
        existingAppointmentStartAt: appointmentStartAt,
      );

      expect(result, normalizeAppointmentDate(appointmentStartAt));
    });
  });
}
