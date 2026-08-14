import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_preparation_eligibility.dart';

void main() {
  group('AppointmentPreparationEligibility', () {
    final today = DateTime(2026, 7, 10, 12);

    test('retorna true para atendimento de hoje dentro da janela', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 10, 12, 30),
          endAt: DateTime(2026, 7, 10, 13, 30),
          now: today,
          beforeStartWindow: AppDurations.appointmentPreparationBeforeStart,
        ),
        isTrue,
      );
    });

    test('retorna true para atendimento em andamento', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.confirmed,
          startAt: DateTime(2026, 7, 10, 11, 30),
          endAt: DateTime(2026, 7, 10, 12, 30),
          now: today,
        ),
        isTrue,
      );
    });

    test('retorna true para atendimento aguardando conclusão após horário', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 10, 9),
          endAt: DateTime(2026, 7, 10, 10),
          now: today,
        ),
        isTrue,
      );
    });

    test('retorna false antes da janela de preparação', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 10, 15),
          endAt: DateTime(2026, 7, 10, 16),
          now: today,
        ),
        isFalse,
      );
    });

    test('retorna false para atendimento concluído', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.completed,
          startAt: DateTime(2026, 7, 10, 11),
          endAt: DateTime(2026, 7, 10, 12),
          now: today,
        ),
        isFalse,
      );
    });

    test('retorna false para atendimento cancelado', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.canceled,
          startAt: DateTime(2026, 7, 10, 11),
          endAt: DateTime(2026, 7, 10, 12),
          now: today,
        ),
        isFalse,
      );
    });

    test('retorna false para atendimento de outro dia', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 7, 11, 11),
          endAt: DateTime(2026, 7, 11, 12),
          now: today,
        ),
        isFalse,
      );
    });
  });

  group('AppointmentPreparationEligibility frozen now 2026-08-13 15:00', () {
    final now = DateTime(2026, 8, 13, 15);

    test('1: mesmo appointment no dia anterior não é elegível', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 8, 12, 14, 30),
          endAt: DateTime(2026, 8, 12, 15, 30),
          now: now,
        ),
        isFalse,
      );
    });

    test('2: futuro fora da janela de 30 min não é elegível', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 8, 13, 16),
          endAt: DateTime(2026, 8, 13, 17),
          now: now,
        ),
        isFalse,
      );
    });

    test('3: appointment dentro da janela é elegível', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 8, 13, 15, 20),
          endAt: DateTime(2026, 8, 13, 16, 20),
          now: now,
        ),
        isTrue,
      );
    });

    test('4: current 14:30–15:30 é elegível', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.pending,
          startAt: DateTime(2026, 8, 13, 14, 30),
          endAt: DateTime(2026, 8, 13, 15, 30),
          now: now,
        ),
        isTrue,
      );
    });

    test('5: completed não é elegível', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.completed,
          startAt: DateTime(2026, 8, 13, 14, 30),
          endAt: DateTime(2026, 8, 13, 15, 30),
          now: now,
        ),
        isFalse,
      );
    });

    test('5: canceled não é elegível', () {
      expect(
        AppointmentPreparationEligibility.isEligible(
          status: AppointmentStatus.canceled,
          startAt: DateTime(2026, 8, 13, 14, 30),
          endAt: DateTime(2026, 8, 13, 15, 30),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
