import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

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
    final statusStyle = _StatusStyle.fromStatus(appointment.status);
    final isNext = !isHighlighted && appointment.status == ScheduleStatus.next;
    final contentOpacity = switch (appointment.status) {
      ScheduleStatus.completed || ScheduleStatus.canceled => 0.78,
      _ => 1.0,
    };
    final durationLabel = appointment.durationLabel?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.purple50
                : isNext
                ? AppColors.purple50
                : AppColors.surface,
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
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.graphite,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    appointment.endTime,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.62),
                                      fontWeight: FontWeight.w400,
                                      height: 1.05,
                                    ),
                                  ),
                                  if (durationLabel != null &&
                                      durationLabel.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      durationLabel,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
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
                            initialTextStyle:
                                theme.textTheme.labelMedium?.copyWith(
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
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.graphite
                                          .withValues(alpha: 0.68),
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
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
        vertical: 3,
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
          letterSpacing: -0.1,
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
        foregroundColor: Color(0xFF2F6B4A),
      ),
      ScheduleStatus.next => const _StatusStyle(
        label: 'Próximo',
        backgroundColor: AppColors.purple100,
        foregroundColor: AppColors.purple800,
      ),
      ScheduleStatus.confirmed => const _StatusStyle(
        label: 'Confirmado',
        backgroundColor: Color(0xFFE7F5EC),
        foregroundColor: Color(0xFF2F6B4A),
      ),
      ScheduleStatus.pending => const _StatusStyle(
        label: 'Pendente',
        backgroundColor: Color(0xFFFFF4E5),
        foregroundColor: Color(0xFFB8741A),
      ),
      ScheduleStatus.canceled => const _StatusStyle(
        label: 'Cancelado',
        backgroundColor: Color(0xFFF3F3F4),
        foregroundColor: AppColors.textSecondary,
      ),
    };
  }
}
