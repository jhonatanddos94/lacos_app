import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';

void main() {
  group('AppointmentOperationalState', () {
    test('identifica estados terminais', () {
      expect(AppointmentOperationalState.completed.isTerminal, isTrue);
      expect(AppointmentOperationalState.canceled.isTerminal, isTrue);
      expect(AppointmentOperationalState.upcoming.isTerminal, isFalse);
      expect(AppointmentOperationalState.current.isTerminal, isFalse);
      expect(AppointmentOperationalState.overdue.isTerminal, isFalse);
    });

    test('prioriza overdue no topo da agenda', () {
      expect(
        AppointmentOperationalState.overdue.agendaSortPriority <
            AppointmentOperationalState.current.agendaSortPriority,
        isTrue,
      );
      expect(
        AppointmentOperationalState.current.agendaSortPriority <
            AppointmentOperationalState.upcoming.agendaSortPriority,
        isTrue,
      );
    });
  });
}
