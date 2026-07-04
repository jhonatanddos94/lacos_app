import 'package:flutter/material.dart';

import 'package:lacos_app/core/constants/app_assets.dart';

/// Cabeçalho de marca das telas de autenticação.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  static const _tabletBreakpoint = 600.0;
  static const _maxLogoWidthPhone = 200.0;
  static const _maxLogoWidthTablet = 240.0;

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
      return (width * 0.32).clamp(0, _maxLogoWidthTablet);
    }

    return (width * 0.42).clamp(0, _maxLogoWidthPhone);
  }
}
