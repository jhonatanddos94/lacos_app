import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_operational_badge_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_operational_badge_chip.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';

const _badgeMapper = AppointmentOperationalBadgeMapper();

class HomeNextAppointmentCard extends StatelessWidget {
  const HomeNextAppointmentCard({
    required this.appointment,
    required this.now,
    required this.onTap,
    super.key,
  });

  static const sectionKey = Key('home-next-appointment');

  final AgendaAppointmentDisplay appointment;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operationalState = appointment.operationalState(now: now);
    final badge = _badgeMapper.resolve(
      operationalState: operationalState,
      isNext: true,
    );
    final isCurrent = operationalState == AppointmentOperationalState.current;
    final title = isCurrent
        ? AppStrings.homeInProgressTitle
        : AppStrings.homeNextAppointmentTitle;
    final timeLabel = formatAppointmentClockTime(appointment.startAt);

    return Semantics(
      button: true,
      label: isCurrent
          ? AppStrings.homeOpenCurrentAppointmentLabel
          : AppStrings.homeOpenNextAppointmentLabel,
      child: Material(
        key: sectionKey,
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderMd,
              boxShadow: AppShadows.level1,
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.purple700,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClientAvatar(
                      name: appointment.clientName,
                      photoUrl: appointment.clientPhotoUrl,
                      radius: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                timeLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.purple800,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxxs),
                              Text(
                                appointment.clientName,
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                                softWrap: true,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.graphite,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (appointment.servicesSummary
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xxxs),
                                Text(
                                  appointment.servicesSummary,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          AppointmentOperationalBadgeChip(presentation: badge),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeNextAppointmentEmpty extends StatelessWidget {
  const HomeNextAppointmentEmpty({super.key});

  static const sectionKey = Key('home-next-appointment-empty');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      key: sectionKey,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Text(
        AppStrings.homeNoNextAppointment,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
