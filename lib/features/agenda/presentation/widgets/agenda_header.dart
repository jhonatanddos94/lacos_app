import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_date_formatters.dart';
import 'package:lacos_app/features/agenda/presentation/mappers/agenda_appointment_display_mapper.dart';

class AgendaHeader extends StatelessWidget {
  const AgendaHeader({
    required this.selectedDay,
    required this.appointments,
    required this.isLoading,
    super.key,
  });

  final DateTime selectedDay;
  final List<AgendaAppointmentDisplay>? appointments;
  final bool isLoading;

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Agenda',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.purple700,
                    size: AppIconSizes.md,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formatAgendaDateLine(selectedDay, isToday: isToday),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _buildSummary(isToday: isToday),
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
          icon: Icons.tune_rounded,
          onPressed: () {},
        ),
      ],
    );
  }

  String _buildSummary({required bool isToday}) {
    if (isLoading) {
      return AppStrings.loading;
    }

    final loadedAppointments = appointments;
    if (loadedAppointments == null) {
      return isToday ? 'Nenhum atendimento hoje' : 'Nenhum atendimento';
    }

    if (loadedAppointments.isEmpty) {
      return isToday ? 'Nenhum atendimento hoje' : 'Nenhum atendimento';
    }

    final countLabel = loadedAppointments.length == 1
        ? '1 atendimento'
        : '${loadedAppointments.length} atendimentos';
    final nextTime = AgendaAppointmentDisplayMapper.nextStartTime(
      loadedAppointments,
      selectedDay,
    );

    if (nextTime == null) {
      return countLabel;
    }

    return '$countLabel • Próximo às $nextTime';
  }
}

class AgendaHeaderIconButton extends StatelessWidget {
  const AgendaHeaderIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;

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
        tooltip: '',
      ),
    );
  }
}
