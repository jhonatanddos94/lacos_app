import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';
import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';

class ClientShortcutCard extends StatelessWidget {
  const ClientShortcutCard({required this.shortcut, super.key});

  static const visualHeight = 44.0;
  static const hitVisualInset =
      (kMinInteractiveDimension - visualHeight) / 2;

  static Key chipKey(ClientListFilter filter) =>
      Key('client-filter-${filter.name}');

  static const selectedFillKey = Key('client-filter-selected-fill');

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
        : Colors.transparent;

    return ColoredBox(
      key: shortcut.isSelected ? selectedFillKey : null,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              style.icon,
              color: foregroundColor,
              size: AppIconSizes.sm,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutStyle {
  const _ShortcutStyle({required this.icon});

  final IconData icon;

  factory _ShortcutStyle.fromType(ClientListFilter type) {
    return switch (type) {
      ClientListFilter.all => const _ShortcutStyle(
        icon: Icons.groups_2_outlined,
      ),
      ClientListFilter.favorites => const _ShortcutStyle(
        icon: Icons.favorite_border_rounded,
      ),
    };
  }
}
