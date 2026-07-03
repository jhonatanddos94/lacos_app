import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

/// Rodapé da tela de login com link para cadastro.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Ainda não tem uma conta?',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppButton(
          label: 'Criar conta',
          variant: AppButtonVariant.text,
          icon: Icons.chevron_right,
          onPressed: () {},
        ),
      ],
    );
  }
}
