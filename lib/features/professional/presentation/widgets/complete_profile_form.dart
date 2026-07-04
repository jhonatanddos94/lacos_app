import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class CompleteProfileForm extends StatelessWidget {
  const CompleteProfileForm({super.key});

  void _completeProfile() {
    // TODO: criar primeiro profissional
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Complete seu perfil',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.purple800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Agora vamos configurar seu perfil profissional.\n\n'
          'Essas informações poderão ser alteradas depois.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppTextField(
          label: 'Nome profissional',
          hint: 'Maria Oliveira',
          helperText: 'Obrigatório',
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: [AutofillHints.name],
          prefixIcon: Icon(Icons.badge_outlined),
        ),
        const SizedBox(height: AppSpacing.sm),
        const AppTextField(
          label: 'Especialidade principal',
          hint: 'Ex.: Cabeleireira, Colorista...',
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          prefixIcon: Icon(Icons.content_cut_outlined),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Concluir configuração',
          onPressed: _completeProfile,
        ),
      ],
    );
  }
}
