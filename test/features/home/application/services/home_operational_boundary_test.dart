import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/application/services/home_operational_boundary.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  group('HomeOperationalBoundary', () {
    test('upcoming usa startAt como próxima fronteira', () {
      final now = DateTime(2026, 8, 13, 15, 59);
      final boundary = HomeOperationalBoundary.next(
        appointments: [
          homeTestAppointment(
            id: 'upcoming',
            clientName: 'Josefa',
            startAt: DateTime(2026, 8, 13, 16, 0),
          ),
        ],
        now: now,
      );

      expect(boundary, DateTime(2026, 8, 13, 16, 0));
    });

    test('current usa endAt como próxima fronteira', () {
      final now = DateTime(2026, 8, 13, 13, 45);
      final boundary = HomeOperationalBoundary.next(
        appointments: [
          homeTestAppointment(
            id: 'current',
            clientName: 'Josefa',
            startAt: DateTime(2026, 8, 13, 13, 30),
          ),
        ],
        now: now,
      );

      expect(boundary, DateTime(2026, 8, 13, 14, 30));
    });

    test('escolhe a fronteira mais próxima entre vários appointments', () {
      final now = DateTime(2026, 8, 13, 14, 0);
      final boundary = HomeOperationalBoundary.next(
        appointments: [
          homeTestAppointment(
            id: 'later',
            clientName: 'Carla',
            startAt: DateTime(2026, 8, 13, 17, 0),
          ),
          homeTestAppointment(
            id: 'sooner',
            clientName: 'Bia',
            startAt: DateTime(2026, 8, 13, 16, 0),
          ),
        ],
        now: now,
      );

      expect(boundary, DateTime(2026, 8, 13, 16, 0));
    });

    test('ignora completed e canceled', () {
      final now = DateTime(2026, 8, 13, 14, 0);
      final boundary = HomeOperationalBoundary.next(
        appointments: [
          homeTestAppointment(
            id: 'done',
            clientName: 'Feita',
            startAt: DateTime(2026, 8, 13, 15, 0),
            status: AppointmentStatus.completed,
          ),
          homeTestAppointment(
            id: 'canceled',
            clientName: 'Cancelada',
            startAt: DateTime(2026, 8, 13, 15, 30),
            status: AppointmentStatus.canceled,
          ),
        ],
        now: now,
      );

      expect(boundary, isNull);
    });

    test('overdue sem próxima fronteira retorna null', () {
      final now = DateTime(2026, 8, 13, 14, 0);
      final boundary = HomeOperationalBoundary.next(
        appointments: [
          homeTestAppointment(
            id: 'overdue',
            clientName: 'Atrasada',
            startAt: DateTime(2026, 8, 13, 10, 0),
          ),
        ],
        now: now,
      );

      expect(boundary, isNull);
    });
  });
}
