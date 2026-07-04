import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

/// Checkbox "Lembrar de mim" e link "Esqueci minha senha".
class LoginFormActions extends StatelessWidget {
  const LoginFormActions({
    required this.rememberMe,
    required this.onRememberMeChanged,
    this.enabled = true,
    super.key,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: InkWell(
            onTap: enabled ? () => onRememberMeChanged(!rememberMe) : null,
            borderRadius: AppRadius.borderXs,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: enabled
                        ? (value) => onRememberMeChanged(value ?? false)
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxxs),
                Flexible(
                  child: Text(
                    'Lembrar de mim',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Esqueci minha senha',
              variant: AppButtonVariant.text,
              onPressed: enabled ? () {} : null,
            ),
          ),
        ),
      ],
    );
  }
}
