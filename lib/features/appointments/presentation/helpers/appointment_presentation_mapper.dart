import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_relative_time_formatter.dart';

class AppointmentPresentationMapper {
  const AppointmentPresentationMapper({
    AppointmentRelativeTimeFormatter? relativeTimeFormatter,
  }) : _relativeTimeFormatter =
           relativeTimeFormatter ?? const AppointmentRelativeTimeFormatter();

  final AppointmentRelativeTimeFormatter _relativeTimeFormatter;

  String estimatedTotalPrefix({
    required AppointmentStatus status,
    AppointmentOperationalState? operationalState,
  }) {
    // Preparado para futura troca quando concluído:
    // return operationalState == AppointmentOperationalState.completed
    //     ? AppStrings.appointmentChargedTotalPrefix
    //     : AppStrings.appointmentEstimatedTotalPrefix;
    return AppStrings.appointmentEstimatedTotalPrefix;
  }

  String overdueBannerMessage() {
    return AppStrings.appointmentOperationalOverdueDetailsMessage;
  }

  String? overdueBannerRelativeTime({
    required DateTime endAt,
    DateTime? now,
  }) {
    final relativeTime = _relativeTimeFormatter.formatOverdueWaitingSince(
      endAt: endAt,
      now: now,
    );

    return relativeTime.isEmpty ? null : relativeTime;
  }
}
