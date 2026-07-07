import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_appointments_list.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_list_card.dart';

class AgendaRefreshingAfterCreateState extends StatelessWidget {
  const AgendaRefreshingAfterCreateState({
    required this.appointments,
    required this.selectedDay,
    this.scrollBottomPadding = 0,
    this.onAppointmentTap,
    super.key,
  });

  final List<AgendaAppointmentDisplay> appointments;
  final DateTime selectedDay;
  final double scrollBottomPadding;
  final ValueChanged<AgendaAppointmentDisplay>? onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AgendaListCard(
      child: appointments.isEmpty
          ? AgendaRefreshingBanner(theme: theme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AgendaRefreshingBanner(theme: theme),
                Expanded(
                  child: AgendaAppointmentsList(
                    appointments: appointments,
                    selectedDay: selectedDay,
                    scrollBottomPadding: scrollBottomPadding,
                    showEmptyState: false,
                    wrapInCard: false,
                    onAppointmentTap: onAppointmentTap,
                  ),
                ),
              ],
            ),
    );
  }
}

class AgendaRefreshingBanner extends StatelessWidget {
  const AgendaRefreshingBanner({
    required this.theme,
    super.key,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            AppStrings.agendaRefreshingAfterCreate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
