import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/application/builders/agenda_operational_summary_builder.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_date_formatters.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_operational_summary_formatter.dart';

class AgendaHeader extends StatelessWidget {
  const AgendaHeader({
    required this.selectedDay,
    required this.appointments,
    required this.isLoading,
    required this.onCalendarPressed,
    this.isPastDay = false,
    this.referenceNow,
    super.key,
  });

  final DateTime selectedDay;
  final List<AgendaAppointmentDisplay>? appointments;
  final bool isLoading;
  final VoidCallback onCalendarPressed;
  final bool isPastDay;
  final DateTime? referenceNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = isSameAppointmentDate(selectedDay, today);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agenda',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatAgendaDateLine(
                  selectedDay,
                  isToday: isToday,
                  isPastDay: isPastDay,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _buildSummary(isToday: isToday, isPastDay: isPastDay),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        AgendaHeaderIconButton(
          icon: Icons.calendar_month_rounded,
          tooltip: AppStrings.agendaOpenCalendar,
          onPressed: onCalendarPressed,
        ),
      ],
    );
  }

  String _buildSummary({required bool isToday, required bool isPastDay}) {
    if (isLoading) {
      return AppStrings.loading;
    }

    if (isPastDay) {
      final loadedAppointments = appointments;
      if (loadedAppointments == null) {
        return AppStrings.agendaHistoricalDayLabel;
      }

      if (loadedAppointments.isEmpty) {
        return AppStrings.agendaHistoricalDayLabel;
      }

      return loadedAppointments.length == 1
          ? '1 atendimento registrado'
          : '${loadedAppointments.length} atendimentos registrados';
    }

    final loadedAppointments = appointments;
    if (loadedAppointments == null) {
      return AppStrings.agendaOperationalSummaryNone;
    }

    if (loadedAppointments.isEmpty) {
      return AppStrings.agendaOperationalSummaryNone;
    }

    final summary = AgendaOperationalSummaryBuilder.build(
      loadedAppointments,
      now: referenceNow,
    );
    return formatAgendaOperationalSummaryLine(summary);
  }
}

class AgendaHeaderIconButton extends StatelessWidget {
  const AgendaHeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderSm,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.purple700,
        iconSize: AppIconSizes.md,
        tooltip: tooltip ?? '',
      ),
    );
  }
}
