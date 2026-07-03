import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';

/// Fundo da tela de login com gradiente e formas decorativas.
class LoginBackground extends StatelessWidget {
  const LoginBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.purple50,
            AppColors.warmWhite,
            AppColors.warmWhite,
          ],
          stops: [0, 0.35, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -72,
            right: -48,
            child: _LoginBlob(
              size: 220,
              color: AppColors.purple200.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            bottom: -96,
            left: -64,
            child: _LoginBlob(
              size: 260,
              color: AppColors.softLilac.withValues(alpha: 0.55),
            ),
          ),
          SizedBox.expand(child: child),
        ],
      ),
    );
  }
}

class _LoginBlob extends StatelessWidget {
  const _LoginBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
