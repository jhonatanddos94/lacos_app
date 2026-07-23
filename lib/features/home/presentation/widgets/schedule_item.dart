import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_operational_badge_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_operational_badge_chip.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

const _badgeMapper = AppointmentOperationalBadgeMapper();

class ScheduleItem extends StatelessWidget {
  const ScheduleItem({
    required this.appointment,
    this.showTimeColumn = true,
    this.isHighlighted = false,
    this.onTap,
    super.key,
  });

  final TodayScheduleAppointment appointment;
  final bool showTimeColumn;
  final bool isHighlighted;
  final VoidCallback? onTap;

  bool get _hasServiceLabel {
    final serviceName = appointment.serviceName.trim();
    return serviceName.isNotEmpty && serviceName != 'Serviços';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgePresentation = _badgeMapper.resolveFromSchedule(
      operationalState: appointment.operationalState,
      status: appointment.status,
    );
    final isNext =
        !isHighlighted &&
        appointment.status == ScheduleStatus.next &&
        appointment.operationalState != AppointmentOperationalState.overdue &&
        appointment.operationalState != AppointmentOperationalState.current;
    final isCompleted =
        appointment.status == ScheduleStatus.completed ||
        appointment.operationalState == AppointmentOperationalState.completed;
    final isCanceled =
        appointment.status == ScheduleStatus.canceled ||
        appointment.operationalState == AppointmentOperationalState.canceled;
    final isOverdue =
        appointment.operationalState == AppointmentOperationalState.overdue;
    final isCurrent =
        appointment.operationalState == AppointmentOperationalState.current;
    final contentOpacity = switch (appointment.operationalState) {
      AppointmentOperationalState.completed => 0.82,
      AppointmentOperationalState.canceled => 0.76,
      _ => switch (appointment.status) {
        ScheduleStatus.completed => 0.82,
        ScheduleStatus.canceled => 0.76,
        _ => 1.0,
      },
    };
    final cardBackgroundColor = isHighlighted
        ? AppColors.purple50
        : isNext
        ? AppColors.purple50
        : isCurrent
        ? AppColors.purple50.withValues(alpha: 0.55)
        : isOverdue
        ? const Color(0xFFFFF8EE)
        : isCompleted
        ? const Color(0xFFF7F8F7)
        : isCanceled
        ? const Color(0xFFF3F3F4)
        : AppColors.surface;
    final durationLabel = appointment.durationLabel?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            border: isHighlighted
                ? Border.all(color: AppColors.purple300, width: 1.5)
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: AppDurations.normal,
                  width: AppSpacing.xxxs,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.purple500
                        : isOverdue
                        ? const Color(0xFFB8741A)
                        : isNext
                        ? AppColors.purple700
                        : Colors.transparent,
                    borderRadius: AppRadius.borderXs,
                  ),
                ),
                Expanded(
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.xs + 2,
                        AppSpacing.sm,
                        AppSpacing.xs + 2,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showTimeColumn) ...[
                            SizedBox(
                              width: 50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.startTime,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.graphite,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    appointment.endTime,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.62,
                                      ),
                                      fontWeight: FontWeight.w400,
                                      height: 1.05,
                                    ),
                                  ),
                                  if (durationLabel != null &&
                                      durationLabel.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      durationLabel,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary
                                                .withValues(alpha: 0.48),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 10,
                                            height: 1,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          ClientAvatar(
                            name: appointment.clientName,
                            photoUrl: appointment.clientPhotoUrl,
                            radius: 18,
                            initialTextStyle: theme.textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.purple800,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.clientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.graphite,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                if (_hasServiceLabel) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    appointment.serviceName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.graphite.withValues(
                                        alpha: 0.68,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                                if (appointment.statusSubtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    appointment.statusSubtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                                if (appointment.statusDetail != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    appointment.statusDetail!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.88,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          AppointmentOperationalBadgeChip(
                            presentation: badgePresentation,
                          ),
                          const SizedBox(width: AppSpacing.xxxs),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: AppIconSizes.md,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
