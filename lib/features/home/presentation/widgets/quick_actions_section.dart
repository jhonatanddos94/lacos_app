import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lacos_app/features/home/presentation/widgets/quick_action_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({required this.actions, super.key});

  final List<QuickActionPreview> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AÇÕES RÁPIDAS',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.purple700,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (actions.isEmpty)
          const HomeEmptyState(
            icon: Icons.flash_on_outlined,
            title: 'Nenhuma ação disponível',
            message:
                'As ações rápidas aparecerão aqui quando estiverem prontas.',
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final action in actions) ...[
                Expanded(child: QuickActionCard(action: action)),
                if (action != actions.last)
                  const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
      ],
    );
  }
}
