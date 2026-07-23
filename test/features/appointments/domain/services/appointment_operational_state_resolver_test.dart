import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_operational_state_resolver.dart';

void main() {
  group('AppointmentOperationalStateResolver', () {
    const resolver = AppointmentOperationalStateResolver();

    final startAt = DateTime(2026, 7, 8, 10);
    final endAt = DateTime(2026, 7, 8, 11);

    AppointmentOperationalState resolve({
      required AppointmentStatus status,
      required DateTime now,
    }) {
      return resolver.resolve(
        status: status,
        startAt: startAt,
        endAt: endAt,
        now: now,
      );
    }

    test('retorna completed e canceled a partir do status persistido', () {
      expect(
        resolve(
          status: AppointmentStatus.completed,
          now: DateTime(2026, 7, 8, 9),
        ),
        AppointmentOperationalState.completed,
      );
      expect(
        resolve(
          status: AppointmentStatus.canceled,
          now: DateTime(2026, 7, 8, 12),
        ),
        AppointmentOperationalState.canceled,
      );
    });

    test('retorna upcoming antes do horário de início', () {
      expect(
        resolve(
          status: AppointmentStatus.pending,
          now: DateTime(2026, 7, 8, 9, 59),
        ),
        AppointmentOperationalState.upcoming,
      );
      expect(
        resolve(
          status: AppointmentStatus.confirmed,
          now: DateTime(2026, 7, 8, 9),
        ),
        AppointmentOperationalState.upcoming,
      );
    });

    test('retorna current durante o atendimento', () {
      expect(
        resolve(
          status: AppointmentStatus.pending,
          now: DateTime(2026, 7, 8, 10),
        ),
        AppointmentOperationalState.current,
      );
      expect(
        resolve(
          status: AppointmentStatus.confirmed,
          now: DateTime(2026, 7, 8, 10, 45),
        ),
        AppointmentOperationalState.current,
      );
    });

    test('retorna overdue após o horário sem alterar o status persistido', () {
      expect(
        resolve(
          status: AppointmentStatus.pending,
          now: DateTime(2026, 7, 8, 11),
        ),
        AppointmentOperationalState.overdue,
      );
      expect(
        resolve(
          status: AppointmentStatus.confirmed,
          now: DateTime(2026, 7, 8, 12),
        ),
        AppointmentOperationalState.overdue,
      );
    });
  });
}
