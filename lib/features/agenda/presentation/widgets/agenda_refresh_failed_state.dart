import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_appointments_list.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_list_card.dart';

class AgendaRefreshAfterCreateFailedState extends StatelessWidget {
  const AgendaRefreshAfterCreateFailedState({
    required this.appointments,
    required this.selectedDay,
    required this.onRetry,
    this.scrollBottomPadding = 0,
    this.onAppointmentTap,
    super.key,
  });

  final List<AgendaAppointmentDisplay> appointments;
  final DateTime selectedDay;
  final double scrollBottomPadding;
  final VoidCallback onRetry;
  final ValueChanged<AgendaAppointmentDisplay>? onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AgendaListCard(
      child: appointments.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
              ),
              child: AgendaRefreshAfterCreateFailedMessage(
                theme: theme,
                onRetry: onRetry,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: AgendaRefreshAfterCreateFailedMessage(
                    theme: theme,
                    onRetry: onRetry,
                  ),
                ),
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

class AgendaRefreshAfterCreateFailedMessage extends StatelessWidget {
  const AgendaRefreshAfterCreateFailedMessage({
    required this.theme,
    required this.onRetry,
    super.key,
  });

  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppStrings.agendaRefreshAfterCreateFailed,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        TextButton(
          onPressed: onRetry,
          child: const Text(AppStrings.agendaRetryUpdate),
        ),
      ],
    );
  }
}
