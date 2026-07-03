import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Variações visuais do [AppButton].
enum AppButtonVariant { primary, secondary, outline, text }

/// Botão oficial do Laços.
///
/// Centraliza todas as ações executáveis da aplicação conforme o
/// Documento 06 — Design System & Experiência.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  static const double _height = 48;
  static const double _iconSize = 20;
  static const double _loadingSize = 20;
  static const double _loadingStrokeWidth = 2;

  bool get _isDisabled => isLoading || onPressed == null;

  EdgeInsets get _defaultPadding => const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xs,
  );

  EdgeInsets get _textPadding => const EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xxs,
  );

  @override
  Widget build(BuildContext context) {
    final style = _styleForVariant(context);
    final effectiveOnPressed = _isDisabled ? null : onPressed;

    return switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.secondary => FilledButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: _buildContent(context),
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: _buildContent(context),
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: _buildContent(context),
      ),
    };
  }

  Widget _buildContent(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: _loadingSize,
              width: _loadingSize,
              child: CircularProgressIndicator(
                strokeWidth: _loadingStrokeWidth,
                color: _loadingColor(context),
              ),
            )
          : _buildLabel(key: const ValueKey('label')),
    );
  }

  Widget _buildLabel({required Key key}) {
    final text = Text(label);

    if (icon == null) {
      return KeyedSubtree(key: key, child: text);
    }

    return KeyedSubtree(
      key: key,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize),
          const SizedBox(width: AppSpacing.xxxs),
          text,
        ],
      ),
    );
  }

  Color _loadingColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (variant) {
      AppButtonVariant.primary => colorScheme.onPrimary,
      AppButtonVariant.secondary => colorScheme.onSecondary,
      AppButtonVariant.outline || AppButtonVariant.text => colorScheme.primary,
    };
  }

  ButtonStyle _styleForVariant(BuildContext context) {
    return switch (variant) {
      AppButtonVariant.primary => _primaryStyle(context),
      AppButtonVariant.secondary => _secondaryStyle(context),
      AppButtonVariant.outline => _outlineStyle(context),
      AppButtonVariant.text => _textStyle(context),
    };
  }

  ButtonStyle _baseStyle(BuildContext context) {
    final textStyle = AppTypography.textTheme(
      brightness: Theme.of(context).brightness,
    ).labelLarge;

    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(64, _height)),
      textStyle: WidgetStateProperty.all(textStyle),
      animationDuration: AppDurations.fast,
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
      ),
    );
  }

  ButtonStyle _primaryStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _baseStyle(context).copyWith(
      padding: WidgetStateProperty.all(_defaultPadding),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.purple200;
        }
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.85);
        }
        return colorScheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.onPrimary.withValues(alpha: 0.6);
        }
        return colorScheme.onPrimary;
      }),
    );
  }

  ButtonStyle _secondaryStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _baseStyle(context).copyWith(
      padding: WidgetStateProperty.all(_defaultPadding),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.secondary.withValues(alpha: 0.5);
        }
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.secondaryContainer;
        }
        return colorScheme.secondary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSecondary.withValues(alpha: 0.4);
        }
        return colorScheme.onSecondary;
      }),
    );
  }

  ButtonStyle _outlineStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _baseStyle(context).copyWith(
      padding: WidgetStateProperty.all(_defaultPadding),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.purple200;
        }
        return colorScheme.primary;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: AppColors.purple200);
        }
        return BorderSide(color: colorScheme.outline);
      }),
    );
  }

  ButtonStyle _textStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _baseStyle(context).copyWith(
      padding: WidgetStateProperty.all(_textPadding),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.purple200;
        }
        return colorScheme.primary;
      }),
    );
  }
}
