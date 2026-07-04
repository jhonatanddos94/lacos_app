import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_durations.dart';

/// Tela inicial exibida ao abrir o aplicativo.
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
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    context.go(RoutePaths.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const _SplashBrand(),
                ),
              ),
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
