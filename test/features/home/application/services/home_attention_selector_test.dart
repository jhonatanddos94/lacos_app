import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/application/services/home_attention_selector.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;

  group('HomeAttentionSelector', () {
    test('zero overdue retorna lista vazia', () {
      final upcoming = homeTestAppointment(
        id: 'upcoming',
        clientName: 'Bia',
        startAt: DateTime(2026, 8, 13, 16, 0),
      );

      expect(HomeAttentionSelector.select([upcoming], now: now), isEmpty);
    });

    test('um overdue é retornado', () {
      final overdue = homeTestAppointment(
        id: 'overdue',
        clientName: 'Atrasada',
        startAt: DateTime(2026, 8, 13, 10, 0),
      );

      final selected = HomeAttentionSelector.select([overdue], now: now);

      expect(selected, hasLength(1));
      expect(selected.first.appointmentId, 'overdue');
    });

    test('vários overdue são ordenados por horário', () {
      final later = homeTestAppointment(
        id: 'later',
        clientName: 'Tarde',
        startAt: DateTime(2026, 8, 13, 11, 0),
      );
      final earlier = homeTestAppointment(
        id: 'earlier',
        clientName: 'Cedo',
        startAt: DateTime(2026, 8, 13, 9, 0),
      );
      final completed = homeTestAppointment(
        id: 'completed',
        clientName: 'Feita',
        startAt: DateTime(2026, 8, 13, 8, 0),
        status: AppointmentStatus.completed,
      );

      final selected = HomeAttentionSelector.select([
        later,
        completed,
        earlier,
      ], now: now);

      expect(selected.map((item) => item.appointmentId), ['earlier', 'later']);
    });
  });
}
