import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_profile_preview.dart';
import 'package:lacos_app/features/memories/application/services/client_memory_profile_preview_service.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memory_highlights_card.dart';

class ClientMemoryHighlightsSection extends ConsumerWidget {
  const ClientMemoryHighlightsSection({
    required this.clientId,
    required this.onViewAll,
    super.key,
  });

  static const memorySkeletonLineKey = Key('client_memory_skeleton_line');

  final String clientId;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(clientMemoriesProvider(clientId));

    return memoriesAsync.when(
      loading: () =>
          _sectionWithSpacing(const _ClientMemoryHighlightsLoadingCard()),
      error: (_, _) => _sectionWithSpacing(
        _ClientMemoryHighlightsErrorCard(
          onRetry: () => ref.invalidate(clientMemoriesProvider(clientId)),
        ),
      ),
      data: (memories) {
        final preview = ClientMemoryProfilePreviewService.resolve(memories);
        if (!preview.hasContent) {
          return const SizedBox.shrink();
        }

        return _sectionWithSpacing(
          _ClientMemoryHighlightsPreviewCard(
            preview: preview,
            onViewAll: onViewAll,
          ),
        );
      },
    );
  }

  Widget _sectionWithSpacing(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _ClientMemoryHighlightsLoadingCard extends StatelessWidget {
  const _ClientMemoryHighlightsLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: AppStrings.clientMemoryImportantLoadingLabel,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.paddingSm,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.level1,
          border: Border.all(color: AppColors.purple100),
        ),
        child: Column(
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
            const _ClientMemoryHighlightsSkeletonBody(),
          ],
        ),
      ),
    );
  }
}

class _ClientMemoryHighlightsSkeletonBody extends StatelessWidget {
  const _ClientMemoryHighlightsSkeletonBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSkeletonBox(
          key: ClientMemoryHighlightsSection.memorySkeletonLineKey,
          width: double.infinity,
          height: 14,
        ),
        const SizedBox(height: AppSpacing.xxxs),
        const AppSkeletonBox(width: double.infinity, height: 14),
        const SizedBox(height: AppSpacing.xxxs),
        const AppSkeletonBox(width: 220, height: 14),
        const SizedBox(height: AppSpacing.xs),
        const Align(
          alignment: Alignment.centerRight,
          child: AppSkeletonBox(width: 88, height: 14),
        ),
      ],
    );
  }
}

class _ClientMemoryHighlightsErrorCard extends StatelessWidget {
  const _ClientMemoryHighlightsErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.level1,
        border: Border.all(color: AppColors.purple100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.memoryImportantTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.purple800,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.clientMemoriesLoadError,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: Text(AppStrings.tryAgain)),
        ],
      ),
    );
  }
}

class _ClientMemoryHighlightsPreviewCard extends StatelessWidget {
  const _ClientMemoryHighlightsPreviewCard({
    required this.preview,
    required this.onViewAll,
  });

  final ClientMemoryProfilePreview preview;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.level1,
        border: Border.all(color: AppColors.purple100),
      ),
      child: ClientMemoryHighlightsPreviewCard(
        preview: preview,
        onViewAll: onViewAll,
      ),
    );
  }
}
