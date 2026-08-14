import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/theme/app_typography.dart';
import 'package:lacos_app/core/widgets/splash_loading_indicator.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';

/// Tela inicial exibida ao abrir o aplicativo.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  /// Chave da marca na Splash — exposta para testes de layout.
  static const brandLogoKey = Key('splash-brand-logo');

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const _minimumSplashDuration = Duration(milliseconds: 1500);

  late final Future<void> _minimumSplashDelay;

  bool _navigationScheduled = false;

  static const _systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.lacosPurple,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    _minimumSplashDelay = Future<void>.delayed(_minimumSplashDuration);
  }

  void _scheduleNavigation(Workspace? workspace) {
    if (_navigationScheduled) return;

    _navigationScheduled = true;
    final destination = AppRouteResolver.resolveFromWorkspace(workspace);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _minimumSplashDelay;

      if (!mounted) return;

      context.go(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemOverlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.purple600,
        body: _SplashBackground(
          child: SafeArea(
            child: Center(
              child: workspaceState.when(
                data: (workspace) {
                  _scheduleNavigation(workspace);
                  return const _SplashLoading();
                },
                loading: () => const _SplashLoading(),
                error: (error, stackTrace) => _SplashError(
                  onRetry: () => ref.invalidate(workspaceProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SplashBrand(),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.splashPreparing,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          AppStrings.splashYourEnvironment,
          textAlign: TextAlign.center,
          style: AppTypography.subtitle(brightness: Brightness.dark),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SplashLoadingIndicator(),
      ],
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SplashBrand(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Não foi possível preparar seu acesso.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Verifique sua conexão e tente novamente.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.onPrimary),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.purple600,
            AppColors.purple700,
            AppColors.lacosPurple,
          ],
          stops: [0, 0.45, 1],
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  /// Fração da largura da tela — reduzida ~25% em relação ao layout anterior
  /// (0,64 → 0,48) para o laço funcionar como assinatura, não ilustração.
  static const _logoWidthFactor = 0.48;

  /// Largura mínima (~25% menor que 220).
  static const _minLogoWidth = 165.0;

  /// Largura máxima (~25% menor que 340) — evita dominar tablets.
  static const _maxLogoWidth = 255.0;

  static double logoWidthForScreenWidth(double screenWidth) {
    return (screenWidth * _logoWidthFactor).clamp(
      _minLogoWidth,
      _maxLogoWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = logoWidthForScreenWidth(MediaQuery.sizeOf(context).width);

    return Image.asset(
      AppAssets.lacosLogo,
      key: SplashPage.brandLogoKey,
      width: logoWidth,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Laços',
    );
  }
}
