import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = AvailabilityEngine();

  final day = DateTime(2025, 7, 6);
  final openingTime = DateTime(2025, 7, 6, 9);
  final closingTime = DateTime(2025, 7, 6, 18);

  group('AvailabilityEngine', () {
    test('sem agendamentos retorna todos os slots possíveis', () {
      final available = engine.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        existingAppointments: const [],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(available.first, DateTime(2025, 7, 6, 9));
      expect(available.last, DateTime(2025, 7, 6, 17));
      expect(available.length, 33);
    });

    test('agendamento 09:00–10:00 remove horários conflitantes', () {
      final available = engine.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(available, isNot(contains(DateTime(2025, 7, 6, 9))));
      expect(available, isNot(contains(DateTime(2025, 7, 6, 9, 15))));
      expect(available, isNot(contains(DateTime(2025, 7, 6, 9, 30))));
      expect(available, isNot(contains(DateTime(2025, 7, 6, 9, 45))));
      expect(available, contains(DateTime(2025, 7, 6, 10)));
    });

    test('horário encostado 10:00 é permitido após 09:00–10:00', () {
      final available = engine.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(available, contains(DateTime(2025, 7, 6, 10)));
    });

    test('appointment cancelado é ignorado', () {
      final available = engine.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
            status: AppointmentStatus.canceled,
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(available, contains(DateTime(2025, 7, 6, 9)));
    });

    test('durationMinutes maior que expediente retorna lista vazia', () {
      final available = engine.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 600,
        existingAppointments: const [],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(available, isEmpty);
    });

    test('exemplo da agenda V1 com dois agendamentos existentes', () {
      final available = engine.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
          ),
          _appointment(
            start: DateTime(2025, 7, 6, 14),
            end: DateTime(2025, 7, 6, 15, 30),
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(available, contains(DateTime(2025, 7, 6, 10)));
      expect(available, contains(DateTime(2025, 7, 6, 13)));
      expect(available, contains(DateTime(2025, 7, 6, 15, 30)));
      expect(available, isNot(contains(DateTime(2025, 7, 6, 9))));
      expect(available, isNot(contains(DateTime(2025, 7, 6, 14, 30))));
    });
    test('isIntervalAvailable bloqueia sobreposição para a mesma profissional', () {
      final isAvailable = engine.isIntervalAvailable(
        startAt: DateTime(2025, 7, 6, 9),
        endAt: DateTime(2025, 7, 6, 10),
        professionalId: 'professional-1',
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(isAvailable, isFalse);
    });

    test('isIntervalAvailable permite horário encostado', () {
      final isAvailable = engine.isIntervalAvailable(
        startAt: DateTime(2025, 7, 6, 10),
        endAt: DateTime(2025, 7, 6, 11),
        professionalId: 'professional-1',
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(isAvailable, isTrue);
    });

    test('isIntervalAvailable ignora appointment cancelado', () {
      final isAvailable = engine.isIntervalAvailable(
        startAt: DateTime(2025, 7, 6, 9),
        endAt: DateTime(2025, 7, 6, 10),
        professionalId: 'professional-1',
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
            status: AppointmentStatus.canceled,
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(isAvailable, isTrue);
    });

    test('isIntervalAvailable bloqueia pending e confirmed', () {
      for (final status in [
        AppointmentStatus.pending,
        AppointmentStatus.confirmed,
      ]) {
        final isAvailable = engine.isIntervalAvailable(
          startAt: DateTime(2025, 7, 6, 9),
          endAt: DateTime(2025, 7, 6, 10),
          professionalId: 'professional-1',
          existingAppointments: [
            _appointment(
              start: DateTime(2025, 7, 6, 9),
              end: DateTime(2025, 7, 6, 10),
              status: status,
            ),
          ],
          openingTime: openingTime,
          closingTime: closingTime,
        );

        expect(isAvailable, isFalse, reason: status.name);
      }
    });
  });
}

Appointment _appointment({
  required DateTime start,
  required DateTime end,
  bool isActive = true,
  AppointmentStatus status = AppointmentStatus.confirmed,
}) {
  final now = DateTime(2025, 7, 6);

  return Appointment(
    id: 'appointment-${start.hour}-${start.minute}',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: start,
    endAt: end,
    status: status,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}
