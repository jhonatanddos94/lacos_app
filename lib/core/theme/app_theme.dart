import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lacos_app/core/config/app_durations.dart';

import 'app_colors.dart';
import 'app_icon_sizes.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema Material 3 oficial do Laços.
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = isLight ? _lightColorScheme : _darkColorScheme;
    final textTheme = AppTypography.textTheme(brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.warmWhite : const Color(0xFF1C1C1E),
      dividerColor: isLight ? AppColors.divider : const Color(0xFF3A3A3E),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor:
            isLight ? AppColors.warmWhite : const Color(0xFF1C1C1E),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shadowColor: AppShadows.shadowColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: AppColors.purple200,
          disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.6),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
          textStyle: textTheme.labelLarge,
          animationDuration: AppDurations.fast,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
          textStyle: textTheme.labelLarge,
          animationDuration: AppDurations.fast,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
          animationDuration: AppDurations.fast,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
          textStyle: textTheme.labelLarge,
          animationDuration: AppDurations.fast,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        border: AppRadius.inputBorder(colorScheme.outline),
        enabledBorder: AppRadius.inputBorder(colorScheme.outline),
        focusedBorder: AppRadius.inputBorder(colorScheme.primary, width: 1.5),
        errorBorder: AppRadius.inputBorder(AppColors.softRose),
        focusedErrorBorder: AppRadius.inputBorder(AppColors.softRose, width: 1.5),
        disabledBorder: AppRadius.inputBorder(
          colorScheme.outline.withValues(alpha: 0.5),
        ),
        labelStyle: textTheme.labelLarge,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.softRose),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.softLilac,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xxxs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXs),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        shadowColor: AppShadows.shadowColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        shadowColor: AppShadows.shadowColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.graphite,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.divider : const Color(0xFF3A3A3E),
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return AppColors.surface.withValues(alpha: 0);
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXs),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: AppColors.purple100,
        circularTrackColor: AppColors.purple100,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppIconSizes.md,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minVerticalPadding: AppSpacing.xxs,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ColorScheme get _lightColorScheme {
    return ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lacosPurple,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.purple100,
      onPrimaryContainer: AppColors.purple900,
      secondary: AppColors.softLilac,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.purple50,
      onSecondaryContainer: AppColors.purple800,
      tertiary: AppColors.softBlue,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: const Color(0xFFDCEAF5),
      onTertiaryContainer: const Color(0xFF1E3A52),
      error: AppColors.softRose,
      onError: AppColors.onError,
      errorContainer: const Color(0xFFFCE8EB),
      onErrorContainer: const Color(0xFF5C2A32),
      surface: AppColors.surface,
      onSurface: AppColors.graphite,
      surfaceContainerHighest: const Color(0xFFF0EEEA),
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.divider,
      outlineVariant: const Color(0xFFF3F1ED),
      shadow: AppShadows.shadowColor,
      scrim: AppColors.graphite,
      inverseSurface: AppColors.graphite,
      onInverseSurface: AppColors.warmWhite,
      inversePrimary: AppColors.purple200,
    );
  }

  static ColorScheme get _darkColorScheme {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.purple300,
      onPrimary: AppColors.purple900,
      primaryContainer: AppColors.purple700,
      onPrimaryContainer: AppColors.purple100,
      secondary: AppColors.purple800,
      onSecondary: AppColors.purple100,
      secondaryContainer: AppColors.purple900,
      onSecondaryContainer: AppColors.purple100,
      tertiary: AppColors.softBlue,
      onTertiary: AppColors.purple900,
      tertiaryContainer: const Color(0xFF1E3A52),
      onTertiaryContainer: const Color(0xFFDCEAF5),
      error: AppColors.softRose,
      onError: AppColors.onError,
      errorContainer: const Color(0xFF5C2A32),
      onErrorContainer: const Color(0xFFFCE8EB),
      surface: const Color(0xFF2C2C2E),
      onSurface: const Color(0xFFE8E8EC),
      surfaceContainerHighest: const Color(0xFF3A3A3E),
      onSurfaceVariant: const Color(0xFFA1A1AA),
      outline: const Color(0xFF3A3A3E),
      outlineVariant: const Color(0xFF2C2C2E),
      shadow: AppShadows.shadowColor,
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFFE8E8EC),
      onInverseSurface: AppColors.graphite,
      inversePrimary: AppColors.purple600,
    );
  }
}
