import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/application/services/home_upcoming_days_service.dart';

void main() {
  final today = DateTime(2026, 8, 13);

  Appointment appointment({
    required String id,
    required DateTime startAt,
    AppointmentStatus status = AppointmentStatus.pending,
  }) {
    return Appointment(
      id: id,
      salonId: 'salon-1',
      ownerId: 'owner-1',
      clientId: 'client-$id',
      professionalId: 'professional-1',
      startAt: startAt,
      endAt: startAt.add(const Duration(hours: 1)),
      status: status,
      isActive: true,
      createdAt: startAt,
      updatedAt: startAt,
    );
  }

  group('HomeUpcomingDaysService.resolveRange', () {
    test('startInclusive é amanhã 00:00', () {
      final range = HomeUpcomingDaysService.resolveRange(today);

      expect(range.startInclusive, DateTime(2026, 8, 14));
    });

    test('endExclusive é hoje + 8 dias 00:00', () {
      final range = HomeUpcomingDaysService.resolveRange(today);

      expect(range.endExclusive, DateTime(2026, 8, 21));
    });
  });

  group('HomeUpcomingDaysService.buildFromAppointments', () {
    test('amanhã com 1 appointment', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 14, 10)),
        ],
      );

      expect(result, hasLength(1));
      expect(result.first.day, DateTime(2026, 8, 14));
      expect(result.first.appointmentCount, 1);
    });

    test('amanhã com vários appointments', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 14, 9)),
          appointment(id: 'a2', startAt: DateTime(2026, 8, 14, 14)),
          appointment(id: 'a3', startAt: DateTime(2026, 8, 14, 17)),
        ],
      );

      expect(result, hasLength(1));
      expect(result.first.appointmentCount, 3);
    });

    test('dias vazios são ignorados', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 14, 10)),
          appointment(id: 'a2', startAt: DateTime(2026, 8, 16, 10)),
        ],
      );

      expect(result, hasLength(2));
      expect(result.map((day) => day.day), [
        DateTime(2026, 8, 14),
        DateTime(2026, 8, 16),
      ]);
    });

    test('retorna até 3 dias ocupados', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 14, 10)),
          appointment(id: 'a2', startAt: DateTime(2026, 8, 15, 10)),
          appointment(id: 'a3', startAt: DateTime(2026, 8, 16, 10)),
        ],
      );

      expect(result, hasLength(3));
    });

    test('4+ dias ocupados retorna somente 3', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 14, 10)),
          appointment(id: 'a2', startAt: DateTime(2026, 8, 15, 10)),
          appointment(id: 'a3', startAt: DateTime(2026, 8, 16, 10)),
          appointment(id: 'a4', startAt: DateTime(2026, 8, 17, 10)),
        ],
      );

      expect(result, hasLength(3));
      expect(result.last.day, DateTime(2026, 8, 16));
    });

    test('ordenação cronológica', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 18, 10)),
          appointment(id: 'a2', startAt: DateTime(2026, 8, 15, 10)),
          appointment(id: 'a3', startAt: DateTime(2026, 8, 20, 10)),
        ],
      );

      expect(result.map((day) => day.day), [
        DateTime(2026, 8, 15),
        DateTime(2026, 8, 18),
        DateTime(2026, 8, 20),
      ]);
    });

    test('pending conta', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(
            id: 'a1',
            startAt: DateTime(2026, 8, 14, 10),
            status: AppointmentStatus.pending,
          ),
        ],
      );

      expect(result.first.appointmentCount, 1);
    });

    test('confirmed conta', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(
            id: 'a1',
            startAt: DateTime(2026, 8, 14, 10),
            status: AppointmentStatus.confirmed,
          ),
        ],
      );

      expect(result.first.appointmentCount, 1);
    });

    test('canceled não conta', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(
            id: 'a1',
            startAt: DateTime(2026, 8, 14, 10),
            status: AppointmentStatus.canceled,
          ),
        ],
      );

      expect(result, isEmpty);
    });

    test('completed não conta', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(
            id: 'a1',
            startAt: DateTime(2026, 8, 14, 10),
            status: AppointmentStatus.completed,
          ),
        ],
      );

      expect(result, isEmpty);
    });

    test('hoje não entra', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 13, 18)),
        ],
      );

      expect(result, isEmpty);
    });

    test('D+7 entra', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 20, 10)),
        ],
      );

      expect(result, hasLength(1));
      expect(result.first.day, DateTime(2026, 8, 20));
    });

    test('D+8 não entra', () {
      final result = HomeUpcomingDaysService.buildFromAppointments(
        today: today,
        appointments: [
          appointment(id: 'a1', startAt: DateTime(2026, 8, 21, 10)),
        ],
      );

      expect(result, isEmpty);
    });
  });
}
