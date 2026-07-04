import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/router/app_route_resolver.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_durations.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/core/workspace/domain/entities/workspace.dart';

/// Tela inicial exibida ao abrir o aplicativo.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _minimumSplashDuration = Duration(milliseconds: 1500);

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
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

    _controller = AnimationController(vsync: this, duration: AppDurations.slow);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
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
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
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
        ),
      ),
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SplashBrand(),
        SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.onPrimary,
          ),
        ),
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

  static const _maxLogoWidth = 340.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = (screenWidth * 0.64).clamp(220.0, _maxLogoWidth);

    return Image.asset(
      AppAssets.logoSplash,
      width: logoWidth,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Laços',
    );
  }
}
