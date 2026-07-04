import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class ClientsSearchBar extends StatelessWidget {
  const ClientsSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.level1,
          border: Border.all(color: AppColors.divider),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: AppIconSizes.md,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    'Buscar cliente ou memória...',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                color: AppColors.divider,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
                color: AppColors.purple700,
                iconSize: AppIconSizes.md,
                tooltip: '',
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
