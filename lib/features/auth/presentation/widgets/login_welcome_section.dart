import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

/// Mensagem de boas-vindas da tela de login.
class LoginWelcomeSection extends StatelessWidget {
  const LoginWelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Bem-vinda de volta!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.purple800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Acesse sua conta para continuar cuidando dos seus '
          'atendimentos e fortalecendo vínculos.',
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
