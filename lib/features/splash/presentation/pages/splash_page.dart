import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_durations.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

/// Tela inicial exibida ao abrir o aplicativo.
///
/// Responsável apenas pela apresentação visual. A orquestração de
/// autenticação e navegação pertence à camada Application.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _loaderFadeAnimation;

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
    _loaderFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
    _controller.forward();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future<void>.delayed(AppDurations.slow);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.lacosPurple,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemOverlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.purple600,
        body: _SplashBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Center(child: _SplashBrand()),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _loaderFadeAnimation,
                  child: const Center(child: _SplashLoader()),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
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

  static const _tabletBreakpoint = 600.0;
  static const _smallPhoneBreakpoint = 360.0;
  static const _tabletMaxFontSize = 96.0;

  @override
  Widget build(BuildContext context) {
    final fontSize = _fontSize(MediaQuery.sizeOf(context));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        'Laços',
        textAlign: TextAlign.center,
        style: GoogleFonts.greatVibes(
          fontSize: fontSize,
          height: 1.1,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }

  double _fontSize(Size screenSize) {
    final width = screenSize.width;
    final shortestSide = screenSize.shortestSide;

    if (shortestSide >= _tabletBreakpoint) {
      return (width * 0.14).clamp(0, _tabletMaxFontSize);
    }

    if (width <= _smallPhoneBreakpoint) {
      return width * 0.18;
    }

    return width * 0.16;
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.md,
      height: AppSpacing.md,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.onPrimary.withValues(alpha: 0.4),
      ),
    );
  }
}
