import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class AppointmentOperationalBadgePresentation {
  const AppointmentOperationalBadgePresentation({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}

class AppointmentOperationalBadgeMapper {
  const AppointmentOperationalBadgeMapper();

  AppointmentOperationalBadgePresentation resolve({
    required AppointmentOperationalState operationalState,
    bool isNext = false,
  }) {
    return switch (operationalState) {
      AppointmentOperationalState.overdue =>
        const AppointmentOperationalBadgePresentation(
          label: AppStrings.appointmentOperationalStateOverdueLabel,
          backgroundColor: Color(0xFFFFF4E5),
          foregroundColor: Color(0xFFB8741A),
        ),
      AppointmentOperationalState.current =>
        const AppointmentOperationalBadgePresentation(
          label: AppStrings.appointmentOperationalStateCurrentLabel,
          backgroundColor: AppColors.purple100,
          foregroundColor: AppColors.purple800,
        ),
      AppointmentOperationalState.upcoming =>
        AppointmentOperationalBadgePresentation(
          label: isNext
              ? AppStrings.appointmentOperationalStateNextLabel
              : AppStrings.appointmentOperationalStateUpcomingLabel,
          backgroundColor: isNext
              ? AppColors.purple100
              : const Color(0xFFF4F4F6),
          foregroundColor: isNext ? AppColors.purple800 : AppColors.graphite,
        ),
      AppointmentOperationalState.completed =>
        const AppointmentOperationalBadgePresentation(
          label: AppStrings.appointmentOperationalStateCompletedLabel,
          backgroundColor: Color(0xFFE7F5EC),
          foregroundColor: Color(0xFF2F6B4A),
        ),
      AppointmentOperationalState.canceled =>
        const AppointmentOperationalBadgePresentation(
          label: AppStrings.appointmentOperationalStateCanceledLabel,
          backgroundColor: Color(0xFFFCE8EA),
          foregroundColor: Color(0xFF9B4A54),
        ),
    };
  }

  AppointmentOperationalBadgePresentation resolveFromSchedule({
    required AppointmentOperationalState? operationalState,
    required ScheduleStatus status,
  }) {
    if (operationalState != null) {
      return resolve(
        operationalState: operationalState,
        isNext: status == ScheduleStatus.next,
      );
    }

    return switch (status) {
      ScheduleStatus.completed => resolve(
        operationalState: AppointmentOperationalState.completed,
      ),
      ScheduleStatus.canceled => resolve(
        operationalState: AppointmentOperationalState.canceled,
      ),
      ScheduleStatus.next => resolve(
        operationalState: AppointmentOperationalState.upcoming,
        isNext: true,
      ),
      ScheduleStatus.pending || ScheduleStatus.confirmed => resolve(
        operationalState: AppointmentOperationalState.upcoming,
      ),
    };
  }
}
