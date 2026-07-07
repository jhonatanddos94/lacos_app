import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';

void main() {
  group('formatAppointmentCancellationReasonDisplay', () {
    test('retorna o motivo quando informado', () {
      expect(
        formatAppointmentCancellationReasonDisplay('Cliente desistiu'),
        'Cliente desistiu',
      );
    });

    test('retorna fallback quando motivo é null', () {
      expect(
        formatAppointmentCancellationReasonDisplay(null),
        AppStrings.appointmentCancellationReasonNotProvided,
      );
    });

    test('retorna fallback quando motivo é vazio ou só espaços', () {
      expect(
        formatAppointmentCancellationReasonDisplay(''),
        AppStrings.appointmentCancellationReasonNotProvided,
      );
      expect(
        formatAppointmentCancellationReasonDisplay('   '),
        AppStrings.appointmentCancellationReasonNotProvided,
      );
    });
  });
}
