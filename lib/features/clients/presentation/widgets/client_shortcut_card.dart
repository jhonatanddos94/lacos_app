import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';

class ClientShortcutCard extends StatelessWidget {
  const ClientShortcutCard({
    required this.shortcut,
    this.compact = false,
    super.key,
  });

  static const _iconContainerSize = 32.0;
  static const _iconSize = 18.0;

  final ClientShortcutPreview shortcut;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _ShortcutStyle.fromType(shortcut.type);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: () {},
        borderRadius: AppRadius.borderMd,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            boxShadow: AppShadows.level1,
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: _iconContainerSize,
                height: _iconContainerSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple50,
                ),
                child: Icon(
                  style.icon,
                  color: AppColors.purple700,
                  size: _iconSize,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shortcut.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      shortcut.subtitle,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: AppIconSizes.sm,
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
      ClientShortcutType.today => const _ShortcutStyle(
          icon: Icons.event_available_outlined,
        ),
      ClientShortcutType.birthdays => const _ShortcutStyle(
          icon: Icons.cake_outlined,
        ),
      ClientShortcutType.reconnect => const _ShortcutStyle(
          icon: Icons.refresh_rounded,
        ),
    };
  }
}
