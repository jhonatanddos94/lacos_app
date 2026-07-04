import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({required this.action, super.key});

  static const _iconContainerSize = 48.0;
  static const _iconSize = AppIconSizes.sm;
  static const _textLineHeight = 1.2;
  static const _textLines = 2;

  final QuickActionPreview action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _QuickActionStyle.fromType(action.type);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: AppColors.graphite,
      fontWeight: FontWeight.w700,
      height: _textLineHeight,
    );
    final fontSize = textStyle?.fontSize ?? 14;
    final textBlockHeight = fontSize * _textLineHeight * _textLines;
    final cardHeight =
        AppSpacing.sm * 2 +
        _iconContainerSize +
        AppSpacing.xs +
        textBlockHeight;

    return Material(
      color: style.backgroundColor,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: () {},
        borderRadius: AppRadius.borderMd,
        child: Container(
          height: cardHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            boxShadow: AppShadows.level1,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: _iconContainerSize,
                width: _iconContainerSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: style.iconBackgroundColor,
                  ),
                  child: Icon(
                    style.icon,
                    color: style.iconColor,
                    size: _iconSize,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: textBlockHeight,
                child: Center(
                  child: Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: _textLines,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionStyle {
  const _QuickActionStyle({
    required this.icon,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;

  factory _QuickActionStyle.fromType(QuickActionType type) {
    return switch (type) {
      QuickActionType.appointment => const _QuickActionStyle(
        icon: Icons.edit_calendar_outlined,
        backgroundColor: AppColors.purple50,
        iconBackgroundColor: AppColors.lacosPurple,
        iconColor: AppColors.onPrimary,
      ),
      QuickActionType.client => const _QuickActionStyle(
        icon: Icons.person_add_alt_1_outlined,
        backgroundColor: Color(0xFFFFF0F6),
        iconBackgroundColor: Color(0xFFE83E8C),
        iconColor: AppColors.onPrimary,
      ),
      QuickActionType.memory => const _QuickActionStyle(
        icon: Icons.note_alt_outlined,
        backgroundColor: Color(0xFFEFF8F2),
        iconBackgroundColor: AppColors.softGreen,
        iconColor: AppColors.onPrimary,
      ),
    };
  }
}
