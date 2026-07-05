import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/client_highlight_carousel.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class NextAppointmentCard extends StatelessWidget {
  const NextAppointmentCard({required this.appointment, super.key});

  static const _highlightSize = 112.0;

  final NextAppointmentPreview appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.level1,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _AppointmentInfoColumn(appointment: appointment)),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: ClientHighlightCarousel(
                  highlights: appointment.highlights,
                  size: _highlightSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Ver agenda de hoje',
            icon: Icons.calendar_month_outlined,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _AppointmentInfoColumn extends StatelessWidget {
  const _AppointmentInfoColumn({required this.appointment});

  final NextAppointmentPreview appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRÓXIMO ATENDIMENTO',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.purple700,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          appointment.clientName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _AppointmentInfoRow(
          icon: Icons.content_cut_rounded,
          label: appointment.serviceName,
        ),
        const SizedBox(height: AppSpacing.xxs),
        _AppointmentInfoRow(
          icon: Icons.calendar_today_outlined,
          label: appointment.dateLabel,
        ),
        const SizedBox(height: AppSpacing.xxs),
        _AppointmentInfoRow(
          icon: Icons.schedule_rounded,
          label: appointment.timeLabel,
          highlight: true,
        ),
      ],
    );
  }
}

class _AppointmentInfoRow extends StatelessWidget {
  const _AppointmentInfoRow({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AppDurations.normal,
      padding: highlight
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: AppSpacing.xxxs,
            )
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: highlight ? AppColors.purple50 : Colors.transparent,
        borderRadius: AppRadius.borderSm,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: highlight ? AppColors.purple700 : AppColors.purple600,
            size: AppIconSizes.sm,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (highlight
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: highlight
                            ? AppColors.purple700
                            : AppColors.graphite,
                        fontWeight: highlight
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
