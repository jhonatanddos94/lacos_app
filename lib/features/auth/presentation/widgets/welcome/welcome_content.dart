import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class WelcomeContent extends ConsumerStatefulWidget {
  const WelcomeContent({super.key});

  @override
  ConsumerState<WelcomeContent> createState() => _WelcomeContentState();
}

class _WelcomeContentState extends ConsumerState<WelcomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfWorkspaceComplete();
    });
  }

  Future<void> _redirectIfWorkspaceComplete() async {
    ref.invalidate(workspaceProvider);
    final workspace = await ref.read(workspaceProvider.future);

    if (!mounted || workspace == null) return;

    if (workspace.hasSalon && workspace.hasProfessional) {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _WelcomeIcon(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Bem-vinda ao Laços',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.purple800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Seu e-mail foi confirmado com sucesso.\n\n'
          'Agora vamos preparar seu espaço de trabalho.\n\n'
          'Leva menos de 2 minutos.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Começar',
          onPressed: () => context.go(RoutePaths.createSalon),
        ),
      ],
    );
  }
}

class _WelcomeIcon extends StatelessWidget {
  const _WelcomeIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.purple50,
        ),
        child: const Icon(
          Icons.celebration_outlined,
          size: 44,
          color: AppColors.lacosPurple,
        ),
      ),
    );
  }
}
