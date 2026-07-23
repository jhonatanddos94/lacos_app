import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_profile_preview.dart';
import 'package:lacos_app/features/memories/application/policies/client_memory_availability_policy.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_highlights.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoryHighlightsCard extends StatelessWidget {
  const ClientMemoryHighlightsCard({
    required this.highlights,
    this.usedMemoryIds = const {},
    this.onToggleUsed,
    super.key,
  });

  final ClientMemoryHighlights highlights;
  final Set<String> usedMemoryIds;
  final ValueChanged<String>? onToggleUsed;

  bool get _isInteractive => onToggleUsed != null;

  @override
  Widget build(BuildContext context) {
    if (!highlights.hasContent) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.memoryImportantTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.purple800,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (highlights.pinned.isNotEmpty) ...[
          _GroupHeader(
            icon: Icons.star_rounded,
            label: AppStrings.memoryImportantPinnedGroup,
          ),
          const SizedBox(height: AppSpacing.xxxs),
          ...highlights.pinned.map(
            (memory) => _MemoryLine(
              memory: memory,
              isUsed: _isUsed(memory),
              isInteractive: _isInteractive,
              onToggleUsed: onToggleUsed,
            ),
          ),
        ],
        if (highlights.recent.isNotEmpty) ...[
          if (highlights.pinned.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          _GroupHeader(
            icon: Icons.schedule_rounded,
            label: AppStrings.memoryImportantRecentGroup,
          ),
          const SizedBox(height: AppSpacing.xxxs),
          ...highlights.recent.map(
            (memory) => _MemoryLine(
              memory: memory,
              isUsed: _isUsed(memory),
              isInteractive: _isInteractive,
              onToggleUsed: onToggleUsed,
            ),
          ),
        ],
      ],
    );
  }

  bool _isUsed(ClientMemory memory) {
    final memoryId = memory.id;
    if (memoryId == null) {
      return false;
    }

    return usedMemoryIds.contains(memoryId);
  }
}

class ClientMemoryHighlightsPreviewCard extends StatelessWidget {
  const ClientMemoryHighlightsPreviewCard({
    required this.preview,
    required this.onViewAll,
    super.key,
  });

  final ClientMemoryProfilePreview preview;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (!preview.hasContent) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final showPinnedIcon =
        preview.kind == ClientMemoryProfilePreviewKind.pinned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.memoryImportantTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.purple800,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...preview.items.map(
          (memory) =>
              _PreviewLine(memory: memory, showPinnedIcon: showPinnedIcon),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppStrings.memoryImportantViewAll,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.purple700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xxxs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MemoryLine extends StatelessWidget {
  const _MemoryLine({
    required this.memory,
    required this.isUsed,
    required this.isInteractive,
    this.onToggleUsed,
  });

  final ClientMemory memory;
  final bool isUsed;
  final bool isInteractive;
  final ValueChanged<String>? onToggleUsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memoryId = memory.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.graphite,
              height: 1.35,
            ),
          ),
          Expanded(
            child: Text(
              memory.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.graphite,
                height: 1.35,
              ),
            ),
          ),
          if (isInteractive && memoryId != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _UsedToggleButton(
              isUsed: isUsed,
              onPressed: ClientMemoryAvailabilityPolicy.canMention(memory)
                  ? () => onToggleUsed?.call(memoryId)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.memory, required this.showPinnedIcon});

  final ClientMemory memory;
  final bool showPinnedIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPinnedIcon) ...[
            const Icon(
              Icons.star_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xxxs),
          ],
          Expanded(
            child: Text(
              memory.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.graphite,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsedToggleButton extends StatelessWidget {
  const _UsedToggleButton({required this.isUsed, this.onPressed});

  final bool isUsed;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxxs,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: isUsed ? AppColors.purple100 : AppColors.surface,
        foregroundColor: isUsed ? AppColors.purple800 : AppColors.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isUsed
                ? AppColors.purple300
                : AppColors.divider.withValues(alpha: 0.8),
          ),
        ),
      ),
      child: Text(
        AppStrings.memoryImportantUsedAction,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
