import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';

class TodayScheduleSection extends StatelessWidget {
  const TodayScheduleSection({required this.appointments, super.key});

  final List<TodayScheduleAppointment> appointments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'AGENDA DE HOJE',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.purple700,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver todos'),
                  SizedBox(width: AppSpacing.xxxs),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        if (appointments.isEmpty)
          const HomeEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Sem agenda para hoje',
            message: 'Quando houver atendimentos, eles aparecerão nesta lista.',
          )
        else
          ClipRRect(
            borderRadius: AppRadius.borderMd,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderMd,
                boxShadow: AppShadows.level1,
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  for (final appointment in appointments) ...[
                    ScheduleItem(appointment: appointment),
                    if (appointment != appointments.last)
                      const Divider(height: 1, color: AppColors.divider),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
