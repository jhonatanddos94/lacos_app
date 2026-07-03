import 'package:flutter/material.dart';

import 'package:lacos_app/core/constants/app_assets.dart';

/// Cabeçalho de marca da tela de login.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  static const _tabletBreakpoint = 600.0;
  static const _maxLogoWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final logoWidth = _logoWidth(screenSize);

    return Center(
      child: Image.asset(
        AppAssets.logoBrand,
        width: logoWidth,
        fit: BoxFit.contain,
        semanticLabel: 'Laços. Detalhes que criam conexão.',
      ),
    );
  }

  double _logoWidth(Size screenSize) {
    final width = screenSize.width;

    if (screenSize.shortestSide >= _tabletBreakpoint) {
      return (width * 0.40).clamp(0, _maxLogoWidth);
    }

    return (width * 0.55).clamp(0, _maxLogoWidth);
  }
}
