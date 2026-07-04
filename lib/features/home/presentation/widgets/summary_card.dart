import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.metric, super.key});

  final SalonSummaryMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _SummaryStyle.fromType(metric.type);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.backgroundColor,
          ),
          child: Icon(
            style.icon,
            color: style.iconColor,
            size: AppIconSizes.sm,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metric.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                metric.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryStyle {
  const _SummaryStyle({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  factory _SummaryStyle.fromType(SalonSummaryMetricType type) {
    return switch (type) {
      SalonSummaryMetricType.clients => const _SummaryStyle(
        icon: Icons.groups_2_outlined,
        backgroundColor: AppColors.purple50,
        iconColor: AppColors.purple700,
      ),
      SalonSummaryMetricType.appointments => const _SummaryStyle(
        icon: Icons.event_available_outlined,
        backgroundColor: Color(0xFFFFF0F6),
        iconColor: Color(0xFFE83E8C),
      ),
      SalonSummaryMetricType.services => const _SummaryStyle(
        icon: Icons.star_outline_rounded,
        backgroundColor: Color(0xFFEFF8F2),
        iconColor: AppColors.softGreen,
      ),
    };
  }
}
