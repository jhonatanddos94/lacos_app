import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class CompleteProfileForm extends ConsumerStatefulWidget {
  const CompleteProfileForm({super.key});

  @override
  ConsumerState<CompleteProfileForm> createState() =>
      _CompleteProfileFormState();
}

class _CompleteProfileFormState extends ConsumerState<CompleteProfileForm> {
  final _nameController = TextEditingController();
  final _specialtiesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _specialtiesController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (ref.read(createProfessionalControllerProvider).isLoading) return;

    await ref
        .read(createProfessionalControllerProvider.notifier)
        .createProfessional(
          name: _nameController.text,
          specialties: _specialtiesController.text,
        );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveErrorMessage(Object error) {
    return switch (error) {
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ => 'Não foi possível concluir seu perfil. Tente novamente.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(createProfessionalControllerProvider);
    final isLoading = state.isLoading;

    ref.listen<AsyncValue<Professional?>>(
      createProfessionalControllerProvider,
      (previous, next) {
        if (next.hasError) {
          _showMessage(_resolveErrorMessage(next.error!));
          return;
        }

        if (previous?.isLoading == true && next.valueOrNull != null) {
          _showMessage('Perfil profissional criado com sucesso.');
          context.go(AppRouteResolver.resolveAfterProfessionalCreated());
        }
      },
    );

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
        AppTextField(
          label: 'Nome profissional',
          hint: 'Maria Oliveira',
          helperText: 'Obrigatório',
          controller: _nameController,
          enabled: !isLoading,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Especialidade principal',
          hint: 'Ex.: Cabeleireira, Colorista...',
          controller: _specialtiesController,
          enabled: !isLoading,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          prefixIcon: const Icon(Icons.content_cut_outlined),
          onFieldSubmitted: (_) => _completeProfile(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Concluir configuração',
          isLoading: isLoading,
          onPressed: isLoading ? null : _completeProfile,
        ),
      ],
    );
  }
}
