import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class RegisterWelcomeSection extends StatelessWidget {
  const RegisterWelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Crie sua conta',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.purple800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Comece a organizar seus atendimentos e fortalecer o '
          'relacionamento com suas clientes.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
