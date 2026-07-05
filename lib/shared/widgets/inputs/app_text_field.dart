import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_durations.dart';
import '../../../core/theme/app_icon_sizes.dart';

/// Campo de texto oficial do Laços.
///
/// Centraliza toda entrada de dados da aplicação conforme o
/// Documento 06 — Design System & Experiência.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.helperText,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.expands = false,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? helperText;
  final String? errorText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool expands;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final decorationTheme = theme.inputDecorationTheme;
    final effectiveMaxLines = expands ? null : (obscureText ? 1 : maxLines);

    return AnimatedOpacity(
      duration: AppDurations.fast,
      opacity: enabled ? 1 : 0.6,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        autofillHints: autofillHints,
        obscureText: obscureText,
        enabled: enabled,
        readOnly: readOnly,
        expands: expands,
        minLines: expands ? null : minLines,
        maxLines: effectiveMaxLines,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        ),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: _wrapIcon(prefixIcon, theme),
          prefixText: prefixText,
          suffixIcon: _wrapIcon(suffixIcon, theme),
          helperText: _hasError ? null : helperText,
          errorText: _hasError ? errorText : null,
          counterText: maxLength == null ? null : '',
          fillColor: enabled ? null : colorScheme.surfaceContainerHighest,
        ).applyDefaults(decorationTheme),
      ),
    );
  }

  Widget? _wrapIcon(Widget? icon, ThemeData theme) {
    if (icon == null) return null;

    final colorScheme = theme.colorScheme;

    return IconTheme.merge(
      data: IconThemeData(
        color: enabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: AppIconSizes.md,
      ),
      child: icon,
    );
  }
}
