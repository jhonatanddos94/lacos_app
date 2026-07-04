import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';

/// Fundo das telas de autenticação com gradiente e formas decorativas.
class AuthBackground extends StatelessWidget {
  const AuthBackground({required this.child, super.key});

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
            child: _AuthBlob(
              size: 220,
              color: AppColors.purple200.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            bottom: -96,
            left: -64,
            child: _AuthBlob(
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

class _AuthBlob extends StatelessWidget {
  const _AuthBlob({required this.size, required this.color});

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
