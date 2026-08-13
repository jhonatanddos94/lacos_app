import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/application/services/home_next_appointment_selector.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;

  group('HomeNextAppointmentSelector', () {
    test('current tem prioridade sobre upcoming', () {
      final current = homeTestAppointment(
        id: 'current',
        clientName: 'Josefa',
        startAt: DateTime(2026, 8, 13, 13, 30),
      );
      final upcoming = homeTestAppointment(
        id: 'upcoming',
        clientName: 'Carla',
        startAt: DateTime(2026, 8, 13, 16, 0),
      );

      final selected = HomeNextAppointmentSelector.select([
        upcoming,
        current,
      ], now: now);

      expect(selected?.appointmentId, 'current');
    });

    test('escolhe o upcoming mais próximo por horário', () {
      final later = homeTestAppointment(
        id: 'later',
        clientName: 'Ana',
        startAt: DateTime(2026, 8, 13, 18, 0),
      );
      final sooner = homeTestAppointment(
        id: 'sooner',
        clientName: 'Bia',
        startAt: DateTime(2026, 8, 13, 16, 0),
      );

      final selected = HomeNextAppointmentSelector.select([
        later,
        sooner,
      ], now: now);

      expect(selected?.appointmentId, 'sooner');
    });

    test('ignora completed, canceled e overdue', () {
      final completed = homeTestAppointment(
        id: 'completed',
        clientName: 'Concluída',
        startAt: DateTime(2026, 8, 13, 9, 0),
        status: AppointmentStatus.completed,
      );
      final canceled = homeTestAppointment(
        id: 'canceled',
        clientName: 'Cancelada',
        startAt: DateTime(2026, 8, 13, 15, 0),
        status: AppointmentStatus.canceled,
      );
      final overdue = homeTestAppointment(
        id: 'overdue',
        clientName: 'Atrasada',
        startAt: DateTime(2026, 8, 13, 10, 0),
      );

      final selected = HomeNextAppointmentSelector.select([
        completed,
        canceled,
        overdue,
      ], now: now);

      expect(selected, isNull);
    });

    test('retorna upcoming quando não há current', () {
      final upcoming = homeTestAppointment(
        id: 'upcoming',
        clientName: 'Bia',
        startAt: DateTime(2026, 8, 13, 16, 0),
      );

      final selected = HomeNextAppointmentSelector.select([upcoming], now: now);

      expect(selected?.appointmentId, 'upcoming');
    });

    test('nenhum retorno quando a lista está vazia', () {
      expect(HomeNextAppointmentSelector.select(const [], now: now), isNull);
    });
  });
}
