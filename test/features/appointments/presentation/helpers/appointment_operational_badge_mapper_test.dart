import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_operational_badge_mapper.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

void main() {
  group('AppointmentOperationalBadgeMapper', () {
    const mapper = AppointmentOperationalBadgeMapper();

    test('overdue nunca exibe Pendente', () {
      final badge = mapper.resolve(
        operationalState: AppointmentOperationalState.overdue,
      );

      expect(badge.label, AppStrings.appointmentOperationalStateOverdueLabel);
      expect(badge.label, isNot('Pendente'));
      expect(badge.label, isNot('Confirmado'));
    });

    test('current exibe Em andamento', () {
      final badge = mapper.resolve(
        operationalState: AppointmentOperationalState.current,
      );

      expect(badge.label, AppStrings.appointmentOperationalStateCurrentLabel);
    });

    test('upcoming exibe Próximo quando isNext', () {
      final badge = mapper.resolve(
        operationalState: AppointmentOperationalState.upcoming,
        isNext: true,
      );

      expect(badge.label, AppStrings.appointmentOperationalStateNextLabel);
    });

    test('upcoming exibe Agendado quando não é o próximo', () {
      final badge = mapper.resolve(
        operationalState: AppointmentOperationalState.upcoming,
      );

      expect(badge.label, AppStrings.appointmentOperationalStateUpcomingLabel);
      expect(badge.label, isNot('Pendente'));
    });

    test('resolveFromSchedule usa estado operacional quando disponível', () {
      final badge = mapper.resolveFromSchedule(
        operationalState: AppointmentOperationalState.overdue,
        status: ScheduleStatus.pending,
      );

      expect(badge.label, AppStrings.appointmentOperationalStateOverdueLabel);
    });

    test('resolveFromSchedule converte status legado para linguagem operacional', () {
      final pendingBadge = mapper.resolveFromSchedule(
        operationalState: null,
        status: ScheduleStatus.pending,
      );
      final confirmedBadge = mapper.resolveFromSchedule(
        operationalState: null,
        status: ScheduleStatus.confirmed,
      );

      expect(
        pendingBadge.label,
        AppStrings.appointmentOperationalStateUpcomingLabel,
      );
      expect(
        confirmedBadge.label,
        AppStrings.appointmentOperationalStateUpcomingLabel,
      );
    });
  });
}
