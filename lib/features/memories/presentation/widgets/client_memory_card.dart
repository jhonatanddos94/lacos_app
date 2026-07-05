import 'package:flutter/material.dart';

import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoryCard extends StatelessWidget {
  const ClientMemoryCard({
    required this.memory,
    this.onMenuTap,
    super.key,
  });

  static const _bowSize = 18.0;

  final ClientMemory memory;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.xxxs,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.lacosLogo,
                width: _bowSize,
                height: _bowSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: AppSpacing.xxxs),
              Expanded(
                child: Text(
                  _formatMemoryDate(memory.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.more_vert_rounded),
                color: AppColors.textSecondary,
                iconSize: AppIconSizes.sm,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.lg,
                  minHeight: AppSpacing.lg,
                ),
                tooltip: '',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxs),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.sm),
          Text(
            memory.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.graphite,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMemoryDate(DateTime? date) {
  if (date == null) return '';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final memoryDate = DateTime(date.year, date.month, date.day);
  final difference = today.difference(memoryDate).inDays;

  if (difference == 0) return 'Hoje';
  if (difference == 1) return 'Ontem';

  return formatBrazilianDate(date);
}
