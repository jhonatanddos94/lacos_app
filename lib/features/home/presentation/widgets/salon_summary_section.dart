import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lacos_app/features/home/presentation/widgets/summary_card.dart';

class SalonSummarySection extends StatelessWidget {
  const SalonSummarySection({required this.metrics, super.key});

  final List<SalonSummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESUMO DO SALÃO',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.purple700,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (metrics.isEmpty)
          const HomeEmptyState(
            icon: Icons.insights_outlined,
            title: 'Resumo indisponível',
            message: 'Os indicadores do salão aparecerão aqui em breve.',
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderMd,
              boxShadow: AppShadows.level1,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                for (final metric in metrics) ...[
                  Expanded(child: SummaryCard(metric: metric)),
                  if (metric != metrics.last)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                      child: SizedBox(
                        height: 48,
                        child: VerticalDivider(color: AppColors.divider),
                      ),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
