import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/presentation/widgets/service_catalog_tile.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ServicesListSection extends StatelessWidget {
  const ServicesListSection({
    required this.services,
    required this.totalCount,
    required this.hasActiveSearch,
    required this.bottomPadding,
    required this.onServiceTap,
    required this.onServiceMenuTap,
    required this.onCreateFirst,
    required this.onClearSearch,
    super.key,
  });

  static const emptyCtaKey = Key('services-page-empty-cta');
  static const searchEmptyKey = Key('services-page-search-empty');
  static const clearSearchKey = Key('services-page-clear-search');

  final List<Service> services;
  final int totalCount;
  final bool hasActiveSearch;
  final double bottomPadding;
  final ValueChanged<Service> onServiceTap;
  final ValueChanged<Service> onServiceMenuTap;
  final VoidCallback onCreateFirst;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSearchEmpty = hasActiveSearch && services.isEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.servicesListTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (totalCount > 0) ...[
              const SizedBox(width: AppSpacing.xxs),
              Text(
                AppStrings.servicesActiveCount(totalCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (showSearchEmpty)
          _ServicesSearchEmptyState(onClearSearch: onClearSearch)
        else if (services.isEmpty)
          _ServicesEmptyState(onCreateFirst: onCreateFirst)
        else
          for (var index = 0; index < services.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.xs),
            ServiceCatalogTile(
              service: services[index],
              onTap: () => onServiceTap(services[index]),
              onMenuTap: () => onServiceMenuTap(services[index]),
            ),
          ],
      ],
    );
  }
}

class _ServicesEmptyState extends StatelessWidget {
  const _ServicesEmptyState({required this.onCreateFirst});

  final VoidCallback onCreateFirst;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeEmptyState(
          icon: Icons.content_cut_rounded,
          title: AppStrings.servicesEmptyTitle,
          message: AppStrings.servicesEmptyMessage,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          key: ServicesListSection.emptyCtaKey,
          label: AppStrings.servicesEmptyCta,
          onPressed: onCreateFirst,
        ),
      ],
    );
  }
}

class _ServicesSearchEmptyState extends StatelessWidget {
  const _ServicesSearchEmptyState({required this.onClearSearch});

  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ServicesListSection.searchEmptyKey,
      children: [
        const HomeEmptyState(
          icon: Icons.search_rounded,
          title: AppStrings.servicesSearchEmptyTitle,
          message: AppStrings.servicesSearchEmptyMessage,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          key: ServicesListSection.clearSearchKey,
          onPressed: onClearSearch,
          child: const Text(AppStrings.servicesSearchClear),
        ),
      ],
    );
  }
}
