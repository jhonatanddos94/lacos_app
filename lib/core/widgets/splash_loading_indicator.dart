import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

/// Indicador de carregamento da Splash — três lacinhos da marca em sequência.
class SplashLoadingIndicator extends StatefulWidget {
  const SplashLoadingIndicator({super.key});

  @override
  State<SplashLoadingIndicator> createState() => _SplashLoadingIndicatorState();
}

class _SplashLoadingIndicatorState extends State<SplashLoadingIndicator> {
  static const _bowCount = 3;
  static const _separatorOpacity = 0.55;

  int _activeIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(AppDurations.splashBowStep, (_) {
      if (!mounted) return;

      setState(() {
        _activeIndex = (_activeIndex + 1) % _bowCount;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _AnimatedBowStep(isActive: _activeIndex == 0),
        const _SplashBowSeparator(),
        _AnimatedBowStep(isActive: _activeIndex == 1),
        const _SplashBowSeparator(),
        _AnimatedBowStep(isActive: _activeIndex == 2),
      ],
    );
  }
}

class _AnimatedBowStep extends StatelessWidget {
  const _AnimatedBowStep({required this.isActive});

  static const _inactiveOpacity = 0.35;
  static const _activeScale = 1.08;

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isActive ? 1.0 : _inactiveOpacity,
      duration: AppDurations.short,
      curve: Curves.easeInOut,
      child: AnimatedScale(
        scale: isActive ? _activeScale : 1.0,
        duration: AppDurations.short,
        curve: Curves.easeInOut,
        child: Image.asset(
          AppAssets.lacosLogo,
          width: AppIconSizes.lg,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
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
          alpha: _SplashLoadingIndicatorState._separatorOpacity,
        ),
      ),
    );
  }
}
