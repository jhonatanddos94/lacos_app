import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class CreateSalonForm extends ConsumerStatefulWidget {
  const CreateSalonForm({super.key});

  @override
  ConsumerState<CreateSalonForm> createState() => _CreateSalonFormState();
}

class _CreateSalonFormState extends ConsumerState<CreateSalonForm> {
  final _salonNameController = TextEditingController();
  final _professionalNameController = TextEditingController();

  @override
  void dispose() {
    _salonNameController.dispose();
    _professionalNameController.dispose();
    super.dispose();
  }

  Future<void> _createSalon() async {
    if (ref.read(createSalonControllerProvider).isLoading) return;

    await ref
        .read(createSalonControllerProvider.notifier)
        .createSalon(
          name: _salonNameController.text,
          responsibleName: _professionalNameController.text,
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
      _ => 'Não foi possível criar seu salão. Tente novamente.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSalonControllerProvider);
    final isLoading = state.isLoading;
    final theme = Theme.of(context);

    ref.listen<AsyncValue<Salon?>>(createSalonControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        _showMessage(_resolveErrorMessage(next.error!));
        return;
      }

      if (previous?.isLoading == true && next.valueOrNull != null) {
        _showMessage('Salão criado com sucesso.');
        context.go(AppRouteResolver.resolveAfterSalonCreated());
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vamos cadastrar seu salão',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.purple800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Essas informações ajudam a personalizar seu espaço de trabalho '
          'dentro do Laços.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'Nome do salão',
          hint: 'Ex: Studio Laços',
          controller: _salonNameController,
          enabled: !isLoading,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          prefixIcon: const Icon(Icons.storefront_outlined),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Nome da profissional responsável',
          hint: 'Informe seu nome',
          controller: _professionalNameController,
          enabled: !isLoading,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          prefixIcon: const Icon(Icons.person_outline),
          onFieldSubmitted: (_) => _createSalon(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Criar meu salão',
          isLoading: isLoading,
          onPressed: isLoading ? null : _createSalon,
        ),
      ],
    );
  }
}
