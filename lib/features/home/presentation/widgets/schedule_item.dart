import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class ScheduleItem extends StatelessWidget {
  const ScheduleItem({required this.appointment, super.key});

  final TodayScheduleAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStyle = _StatusStyle.fromStatus(appointment.status);
    final initial = appointment.clientName.isEmpty
        ? 'L'
        : appointment.clientName.substring(0, 1);
    final isNext = appointment.status == ScheduleStatus.next;
    final contentOpacity = appointment.status == ScheduleStatus.completed
        ? 0.72
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.startTime,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: isNext
                                        ? AppColors.purple700
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  appointment.endTime,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.purple100,
                            child: Text(
                              initial,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.purple800,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.clientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.graphite,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxxs),
                                Text(
                                  appointment.serviceName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxxs,
                            ),
                            decoration: BoxDecoration(
                              color: statusStyle.backgroundColor,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              statusStyle.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusStyle.foregroundColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
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
        foregroundColor: AppColors.softGreen,
      ),
      ScheduleStatus.next => const _StatusStyle(
        label: 'Próximo',
        backgroundColor: AppColors.purple100,
        foregroundColor: AppColors.purple700,
      ),
    };
  }
}
