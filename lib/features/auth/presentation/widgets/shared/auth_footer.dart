import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/router/route_paths.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_typography.dart';

/// Rodapé reutilizável das telas de autenticação com navegação entre fluxos.
class AuthFooter extends StatelessWidget {
  const AuthFooter.signUp({super.key, this.enabled = true})
      : _variant = _AuthFooterVariant.signUp;

  const AuthFooter.signIn({super.key, this.enabled = true})
      : _variant = _AuthFooterVariant.signIn;

  final bool enabled;
  final _AuthFooterVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    final linkStyle = bodyStyle?.copyWith(
      color: AppColors.lacosPurple,
      fontWeight: AppTypography.semiBold,
    );

    return switch (_variant) {
      _AuthFooterVariant.signUp => Text.rich(
          TextSpan(
            text: 'Ainda não tem uma conta? ',
            style: bodyStyle,
            children: [
              TextSpan(
                text: 'Cadastre-se',
                style: linkStyle,
                recognizer: _tapRecognizer(
                  context,
                  RoutePaths.register,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      _AuthFooterVariant.signIn => Text.rich(
          TextSpan(
            text: 'Já tem uma conta?',
            style: linkStyle,
            recognizer: _tapRecognizer(
              context,
              RoutePaths.login,
            ),
          ),
          textAlign: TextAlign.center,
        ),
    };
  }

  TapGestureRecognizer? _tapRecognizer(BuildContext context, String route) {
    if (!enabled) return null;
    return TapGestureRecognizer()..onTap = () => context.go(route);
  }
}

enum _AuthFooterVariant { signUp, signIn }
