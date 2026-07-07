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

  group('AppointmentStatus.canBeEdited', () {
    test('permite editar agendamentos pendentes e confirmados', () {
      expect(AppointmentStatus.pending.canBeEdited, isTrue);
      expect(AppointmentStatus.confirmed.canBeEdited, isTrue);
    });

    test('bloqueia edição de estados finais', () {
      expect(AppointmentStatus.completed.canBeEdited, isFalse);
      expect(AppointmentStatus.canceled.canBeEdited, isFalse);
    });
  });

  group('AppointmentStatus.canBeCanceled', () {
    test('permite cancelar agendamentos pendentes e confirmados', () {
      expect(AppointmentStatus.pending.canBeCanceled, isTrue);
      expect(AppointmentStatus.confirmed.canBeCanceled, isTrue);
    });

    test('bloqueia cancelamento de estados finais', () {
      expect(AppointmentStatus.completed.canBeCanceled, isFalse);
      expect(AppointmentStatus.canceled.canBeCanceled, isFalse);
    });
  });

  group('AppointmentStatus.countsForCalendarIndicator', () {
    test('conta atendimentos ativos exceto cancelados', () {
      expect(AppointmentStatus.pending.countsForCalendarIndicator, isTrue);
      expect(AppointmentStatus.confirmed.countsForCalendarIndicator, isTrue);
      expect(AppointmentStatus.completed.countsForCalendarIndicator, isTrue);
      expect(AppointmentStatus.canceled.countsForCalendarIndicator, isFalse);
    });
  });
}
