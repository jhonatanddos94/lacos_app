import 'package:flutter/material.dart';

import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

/// Botão de login social com Google.
///
/// Ícone será adicionado quando o asset oficial estiver disponível.
class LoginGoogleButton extends StatelessWidget {
  const LoginGoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Entrar com Google',
      variant: AppButtonVariant.outline,
      onPressed: () {},
    );
  }
}
