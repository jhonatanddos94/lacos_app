import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_search_bar.dart';
import 'package:lacos_app/features/services/application/helpers/service_provider_invalidation.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/application/services/service_catalog_filter.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/presentation/bottom_sheets/service_actions_bottom_sheet.dart';
import 'package:lacos_app/features/services/presentation/helpers/service_form_sheet.dart';
import 'package:lacos_app/features/services/presentation/widgets/service_delete_dialog.dart';
import 'package:lacos_app/features/services/presentation/widgets/services_header.dart';
import 'package:lacos_app/features/services/presentation/widgets/services_list_section.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  static const emptyCtaKey = ServicesListSection.emptyCtaKey;
  static const searchBarKey = Key('services-page-search');
  static const fabKey = Key('services-page-fab');
  static const loadingKey = Key('services-page-loading');
  static const errorRetryKey = Key('services-page-error-retry');

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  static const _fabSize = 56.0;
  static const _maxContentWidth = 560.0;

  final _searchController = TextEditingController();
  var _searchText = '';
  var _isOpeningSheet = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    setState(() => _searchText = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchText = '');
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_isOpeningSheet) return;

    _isOpeningSheet = true;
    try {
      await action();
    } finally {
      _isOpeningSheet = false;
    }
  }

  Future<void> _openServiceForm({Service? service}) {
    return _runGuarded(() async {
      final savedService = await showServiceFormBottomSheet(
        context,
        service: service,
      );

      if (!mounted || savedService == null) return;

      invalidateServicesProvider(ref);
      _showMessage(
        service == null
            ? AppStrings.serviceCreatedSuccess
            : AppStrings.serviceUpdatedSuccess,
      );
    });
  }

  Future<void> _openServiceActions(Service service) {
    return _runGuarded(() async {
      final action = await showModalBottomSheet<ServiceAction>(
        context: context,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
        builder: (context) => const ServiceActionsBottomSheet(),
      );

      if (!mounted || action == null) return;

      switch (action) {
        case ServiceAction.edit:
          final updatedService = await showServiceFormBottomSheet(
            context,
            service: service,
          );
          if (!mounted || updatedService == null) return;
          invalidateServicesProvider(ref);
          _showMessage(AppStrings.serviceUpdatedSuccess);
        case ServiceAction.delete:
          final deleted = await showDialog<bool>(
            context: context,
            builder: (context) => ServiceDeleteDialog(service: service),
          );
          if (!mounted || deleted != true) return;
          invalidateServicesProvider(ref);
          _showMessage(AppStrings.serviceDeletedSuccess);
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshServices() async {
    invalidateServicesProvider(ref);
    await ref.read(servicesProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final hasItems = services.maybeWhen(
      data: (items) => items.isNotEmpty,
      orElse: () => false,
    );
    final bottomInset = hasItems
        ? AppSpacing.sm + _fabSize + AppSpacing.md
        : AppSpacing.md;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ServicesHeader(),
                        if (hasItems) ...[
                          const SizedBox(height: AppSpacing.md),
                          ClientsSearchBar(
                            key: ServicesPage.searchBarKey,
                            controller: _searchController,
                            onChanged: _handleSearchChanged,
                            onClear: _clearSearch,
                            hintText: AppStrings.servicesSearchHint,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: RefreshIndicator(
                        onRefresh: _refreshServices,
                        child: services.when(
                          data: (items) {
                            if (items.isEmpty && _searchText.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _searchText.isNotEmpty) {
                                  _clearSearch();
                                }
                              });
                            }

                            final filtered = filterServicesByName(
                              items,
                              _searchText,
                            );

                            return ServicesListSection(
                              services: filtered,
                              totalCount: items.length,
                              hasActiveSearch: _searchText.trim().isNotEmpty,
                              bottomPadding: bottomInset,
                              onServiceTap: (service) =>
                                  _openServiceForm(service: service),
                              onServiceMenuTap: _openServiceActions,
                              onCreateFirst: () => _openServiceForm(),
                              onClearSearch: _clearSearch,
                            );
                          },
                          loading: () =>
                              _ServicesLoadingState(bottomPadding: bottomInset),
                          error: (error, stackTrace) => _ServicesErrorState(
                            message: _resolveErrorMessage(error),
                            bottomPadding: bottomInset,
                            onRetry: () => invalidateServicesProvider(ref),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasItems)
            Positioned(
              right: AppSpacing.screenHorizontal,
              bottom: AppSpacing.sm,
              child: FloatingActionButton(
                key: ServicesPage.fabKey,
                heroTag: 'services_fab',
                tooltip: AppStrings.servicesAddLabel,
                onPressed: () => _openServiceForm(),
                backgroundColor: AppColors.lacosPurple,
                foregroundColor: AppColors.onPrimary,
                child: const Icon(Icons.add_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServicesLoadingState extends StatelessWidget {
  const _ServicesLoadingState({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ServicesPage.loadingKey,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        for (var index = 0; index < 6; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.xs),
          const AppSkeletonBox(height: 56, width: double.infinity),
        ],
      ],
    );
  }
}

class _ServicesErrorState extends StatelessWidget {
  const _ServicesErrorState({
    required this.message,
    required this.bottomPadding,
    required this.onRetry,
  });

  final String message;
  final double bottomPadding;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Container(
            width: double.infinity,
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  key: ServicesPage.errorRetryKey,
                  onPressed: onRetry,
                  child: const Text(AppStrings.tryAgain),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => AppStrings.servicesLoadError,
  };
}
