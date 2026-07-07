import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

void main() {
  group('AppointmentStatus.canBeCompleted', () {
    test('permite concluir agendamentos pendentes e confirmados', () {
      expect(AppointmentStatus.pending.canBeCompleted, isTrue);
      expect(AppointmentStatus.confirmed.canBeCompleted, isTrue);
    });

    test('bloqueia conclusão de estados finais', () {
      expect(AppointmentStatus.completed.canBeCompleted, isFalse);
      expect(AppointmentStatus.canceled.canBeCompleted, isFalse);
    });
  });
}
