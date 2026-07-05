import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';

class ClientShortcutCard extends StatelessWidget {
  const ClientShortcutCard({
    required this.shortcut,
    super.key,
  });

  final ClientShortcutPreview shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _ShortcutStyle.fromType(shortcut.type);
    final foregroundColor = !shortcut.isEnabled
        ? AppColors.textSecondary
        : shortcut.isSelected
        ? AppColors.onPrimary
        : AppColors.purple700;
    final backgroundColor = shortcut.isSelected
        ? AppColors.lacosPurple
        : AppColors.purple50;

    return Material(
      color: backgroundColor,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: shortcut.isEnabled ? () {} : null,
        borderRadius: AppRadius.borderLg,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: shortcut.isSelected
                  ? AppColors.lacosPurple
                  : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                style.icon,
                color: foregroundColor,
                size: AppIconSizes.sm,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                shortcut.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: shortcut.isSelected
                      ? FontWeight.w800
                      : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutStyle {
  const _ShortcutStyle({required this.icon});

  final IconData icon;

  factory _ShortcutStyle.fromType(ClientShortcutType type) {
    return switch (type) {
      ClientShortcutType.all => const _ShortcutStyle(
          icon: Icons.groups_2_outlined,
        ),
      ClientShortcutType.favorites => const _ShortcutStyle(
          icon: Icons.favorite_border_rounded,
        ),
      ClientShortcutType.recent => const _ShortcutStyle(
          icon: Icons.schedule_rounded,
        ),
      ClientShortcutType.withoutReturn => const _ShortcutStyle(
          icon: Icons.history_toggle_off_rounded,
        ),
    };
  }
}
