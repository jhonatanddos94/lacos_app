import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';

void main() {
  group('AppointmentCanceledBy', () {
    test('converte client e salon do Parse', () {
      expect(
        AppointmentCanceledBy.fromParse('client'),
        AppointmentCanceledBy.client,
      );
      expect(
        AppointmentCanceledBy.fromParse('salon'),
        AppointmentCanceledBy.salon,
      );
    });

    test('valor desconhecido retorna null', () {
      expect(AppointmentCanceledBy.fromParse('unknown'), isNull);
      expect(AppointmentCanceledBy.fromParse(null), isNull);
      expect(AppointmentCanceledBy.fromParse(''), isNull);
    });

    test('toParse persiste valores esperados', () {
      expect(AppointmentCanceledBy.client.toParse(), 'client');
      expect(AppointmentCanceledBy.salon.toParse(), 'salon');
    });
  });
}
