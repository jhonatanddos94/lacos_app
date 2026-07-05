import 'package:flutter/material.dart';

import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

/// Indicador estático de carregamento da Splash — três lacinhos da marca.
///
/// A animação sequencial será implementada em etapa futura.
class SplashLoadingIndicator extends StatelessWidget {
  const SplashLoadingIndicator({super.key});

  static const _inactiveOpacity = 0.35;
  static const _activeOpacity = 1.0;
  static const _separatorOpacity = 0.55;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SplashBowIcon(opacity: _inactiveOpacity),
        const _SplashBowSeparator(),
        const _SplashBowIcon(opacity: _inactiveOpacity),
        const _SplashBowSeparator(),
        const _SplashBowIcon(opacity: _activeOpacity),
      ],
    );
  }
}

class _SplashBowIcon extends StatelessWidget {
  const _SplashBowIcon({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        AppAssets.lacosLogo,
        width: AppIconSizes.lg,
        height: AppIconSizes.lg,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _SplashBowSeparator extends StatelessWidget {
  const _SplashBowSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xxxs,
      height: AppSpacing.xxxs,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.onPrimary.withValues(
          alpha: SplashLoadingIndicator._separatorOpacity,
        ),
      ),
    );
  }
}
