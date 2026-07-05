import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class ScheduleItem extends StatelessWidget {
  const ScheduleItem({
    required this.appointment,
    this.showTimeColumn = true,
    super.key,
  });

  final TodayScheduleAppointment appointment;
  final bool showTimeColumn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStyle = _StatusStyle.fromStatus(appointment.status);
    final initial = appointment.clientName.isEmpty
        ? 'L'
        : appointment.clientName.substring(0, 1);
    final isNext = appointment.status == ScheduleStatus.next;
    final contentOpacity = appointment.status == ScheduleStatus.completed
        ? 0.78
        : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: AnimatedContainer(
          duration: AppDurations.normal,
          color: isNext ? AppColors.purple50 : AppColors.surface,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: AppDurations.normal,
                  width: AppSpacing.xxxs,
                  decoration: BoxDecoration(
                    color: isNext ? AppColors.purple700 : Colors.transparent,
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
                              width: 48,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.startTime,
                                    style:
                                        theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    appointment.endTime,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.75),
                                      fontWeight: FontWeight.w500,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.purple100,
                            child: Text(
                              initial,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.purple800,
                                fontWeight: FontWeight.w800,
                              ),
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
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.spa_outlined,
                                      size: AppIconSizes.sm - 2,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.85),
                                    ),
                                    const SizedBox(width: AppSpacing.xxxs),
                                    Expanded(
                                      child: Text(
                                        appointment.serviceName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          _StatusChip(style: statusStyle),
                          const SizedBox(width: AppSpacing.xxxs),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: AppIconSizes.md,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.55),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.style});

  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: AppRadius.borderSm,
      ),
      child: Text(
        style.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: style.foregroundColor,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  factory _StatusStyle.fromStatus(ScheduleStatus status) {
    return switch (status) {
      ScheduleStatus.completed => const _StatusStyle(
        label: 'Concluído',
        backgroundColor: Color(0xFFE7F5EC),
        foregroundColor: Color(0xFF3D7A5C),
      ),
      ScheduleStatus.next => const _StatusStyle(
        label: 'Próximo',
        backgroundColor: AppColors.purple100,
        foregroundColor: AppColors.purple800,
      ),
    };
  }
}
