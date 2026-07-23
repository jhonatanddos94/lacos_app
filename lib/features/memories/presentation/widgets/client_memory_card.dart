import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/presentation/helpers/client_memory_labels.dart';

class ClientMemoryCard extends StatelessWidget {
  const ClientMemoryCard({
    required this.memory,
    this.onMenuTap,
    this.emphasizeArchivedState = false,
    super.key,
  });

  static const _bowSize = 18.0;
  static const _archivedOpacity = 0.82;

  final ClientMemory memory;
  final VoidCallback? onMenuTap;
  final bool emphasizeArchivedState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayDate = memory.updatedAt ?? memory.createdAt;
    final showArchivedEmphasis = emphasizeArchivedState && memory.isArchived;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.xxxs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: memory.isArchived
              ? AppColors.divider
              : (memory.isPinned ? AppColors.purple200 : AppColors.divider),
        ),
        boxShadow: AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showArchivedEmphasis) ...[
                Icon(
                  Icons.inventory_2_outlined,
                  size: AppIconSizes.sm,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xxxs),
              ] else ...[
                Image.asset(
                  AppAssets.lacosLogo,
                  width: _bowSize,
                  height: _bowSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: AppSpacing.xxxs),
              ],
              Expanded(
                child: Text(
                  showArchivedEmphasis
                      ? AppStrings.memoryArchivedBadge
                      : _formatMemoryDate(displayDate),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (memory.isPinned && !memory.isArchived) ...[
                Icon(
                  Icons.push_pin_rounded,
                  size: AppIconSizes.sm,
                  color: AppColors.purple400,
                ),
                const SizedBox(width: AppSpacing.xxxs),
              ],
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
          Wrap(
            spacing: AppSpacing.xxxs,
            runSpacing: AppSpacing.xxxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MemoryMetaChip(label: ClientMemoryLabels.typeLabel(memory.type)),
              if (ClientMemoryLabels.shouldHighlightPriority(memory.priority))
                _MemoryMetaChip(
                  label: ClientMemoryLabels.priorityLabel(memory.priority),
                  foregroundColor: _priorityColor(memory.priority),
                  backgroundColor: _priorityBackground(memory.priority),
                ),
              if (memory.isPinned && !memory.isArchived)
                _MemoryMetaChip(
                  label: AppStrings.memoryPinnedBadge,
                  foregroundColor: AppColors.purple700,
                  backgroundColor: AppColors.purple50,
                ),
              if (memory.isArchived)
                _MemoryMetaChip(
                  label: AppStrings.memoryArchivedBadge,
                  foregroundColor: AppColors.textSecondary,
                  backgroundColor: AppColors.divider.withValues(alpha: 0.45),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
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

    if (!showArchivedEmphasis) {
      return card;
    }

    return Opacity(opacity: _archivedOpacity, child: card);
  }
}

class _MemoryMetaChip extends StatelessWidget {
  const _MemoryMetaChip({
    required this.label,
    this.foregroundColor = AppColors.purple700,
    this.backgroundColor = AppColors.purple50,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.borderSm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _priorityColor(ClientMemoryPriority priority) {
  return switch (priority) {
    ClientMemoryPriority.high => AppColors.warmAmber,
    ClientMemoryPriority.low => AppColors.textSecondary,
    ClientMemoryPriority.normal => AppColors.graphite,
  };
}

Color _priorityBackground(ClientMemoryPriority priority) {
  return switch (priority) {
    ClientMemoryPriority.high => AppColors.warmAmber.withValues(alpha: 0.12),
    ClientMemoryPriority.low => AppColors.divider.withValues(alpha: 0.65),
    ClientMemoryPriority.normal => AppColors.purple50,
  };
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
