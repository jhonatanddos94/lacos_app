import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_presentation_mapper.dart';

void main() {
  group('AppointmentPresentationMapper', () {
    const mapper = AppointmentPresentationMapper();

    test(
      'retorna total estimado enquanto preparação futura não está ativa',
      () {
        expect(
          mapper.estimatedTotalPrefix(
            status: AppointmentStatus.completed,
            operationalState: AppointmentOperationalState.completed,
          ),
          AppStrings.appointmentEstimatedTotalPrefix,
        );
      },
    );

    test('retorna mensagem natural do banner overdue', () {
      expect(
        mapper.overdueBannerMessage(),
        AppStrings.appointmentOperationalOverdueDetailsMessage,
      );
    });

    test('retorna tempo relativo complementar para overdue', () {
      expect(
        mapper.overdueBannerRelativeTime(
          endAt: DateTime(2026, 7, 8, 10),
          now: DateTime(2026, 7, 8, 11, 15),
        ),
        '${AppStrings.appointmentOperationalOverdueRelativePrefix} há 1h 15min',
      );
    });
  });
}
