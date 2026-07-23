import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_search_bar.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/presentation/bottom_sheets/service_actions_bottom_sheet.dart';
import 'package:lacos_app/features/services/presentation/bottom_sheets/service_form_bottom_sheet.dart';
import 'package:lacos_app/features/services/presentation/widgets/service_delete_dialog.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ServicePickerBottomSheet extends ConsumerStatefulWidget {
  const ServicePickerBottomSheet({super.key});

  @override
  ConsumerState<ServicePickerBottomSheet> createState() =>
      _ServicePickerBottomSheetState();
}

class _ServicePickerBottomSheetState
    extends ConsumerState<ServicePickerBottomSheet> {
  static const _fabSize = 56.0;
  static const _listBottomPadding = AppSpacing.md + _fabSize + AppSpacing.md;

  final _searchController = TextEditingController();
  String _searchText = '';

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

  void _close() {
    Navigator.of(context).pop();
  }

  void _selectService(Service service) {
    Navigator.of(context).pop(service);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openServiceActions(Service service) async {
    final action = await showModalBottomSheet<ServiceAction>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const ServiceActionsBottomSheet(),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case ServiceAction.edit:
        await _openEditServiceForm(service);
      case ServiceAction.delete:
        await _openDeleteServiceDialog(service);
    }
  }

  Future<void> _openEditServiceForm(Service service) async {
    final updatedService = await showModalBottomSheet<Service>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => ServiceFormBottomSheet(service: service),
    );

    if (!mounted || updatedService == null) return;

    ref.invalidate(servicesProvider);
    _showMessage(AppStrings.serviceUpdatedSuccess);
  }

  Future<void> _openDeleteServiceDialog(Service service) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => ServiceDeleteDialog(service: service),
    );

    if (!mounted || deleted != true) return;

    ref.invalidate(servicesProvider);
    _showMessage(AppStrings.serviceDeletedSuccess);
  }

  Future<void> _openCreateServiceForm() async {
    final createdService = await showModalBottomSheet<Service>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const ServiceFormBottomSheet(),
    );

    if (!mounted || createdService == null) return;

    ref.invalidate(servicesProvider);
    _selectService(createdService);
  }

  List<Service> _filterServices(List<Service> services) {
    final activeServices = services
        .where((service) => service.isActive)
        .toList(growable: false);

    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) {
      return activeServices;
    }

    return activeServices
        .where((service) {
          final name = service.name.toLowerCase();
          final category = service.category?.toLowerCase() ?? '';

          return name.contains(query) || category.contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.85;
    final servicesAsync = ref.watch(servicesProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  const _SheetHandle(),
                  Padding(
                    padding: AppSpacing.screenPadding.copyWith(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        _HeaderIconButton(
                          icon: Icons.close_rounded,
                          onPressed: _close,
                          tooltip: AppStrings.cancel,
                        ),
                        Expanded(
                          child: Text(
                            AppStrings.servicePickerTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.graphite,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: AppSpacing.screenPadding.copyWith(
                      top: 0,
                      bottom: AppSpacing.sm,
                    ),
                    child: ClientsSearchBar(
                      controller: _searchController,
                      onChanged: _handleSearchChanged,
                      onClear: _clearSearch,
                      hintText: AppStrings.servicePickerSearchHint,
                    ),
                  ),
                  Expanded(
                    child: servicesAsync.when(
                      data: (services) {
                        final filteredServices = _filterServices(services);

                        if (filteredServices.isEmpty) {
                          return _ServicePickerEmptyState(
                            onNewServiceTap: _openCreateServiceForm,
                            bottomPadding: _listBottomPadding,
                          );
                        }

                        return ListView.separated(
                          padding: AppSpacing.screenPadding.copyWith(
                            top: 0,
                            bottom: _listBottomPadding,
                          ),
                          itemCount: filteredServices.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final service = filteredServices[index];
                            return _ServicePickerTile(
                              service: service,
                              onTap: () => _selectService(service),
                              onMenuTap: () => _openServiceActions(service),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: SizedBox.square(
                          dimension: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                      error: (error, stackTrace) => _ServicePickerErrorState(
                        message: _resolveErrorMessage(error),
                        onRetry: () => ref.invalidate(servicesProvider),
                        bottomPadding: _listBottomPadding,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: FloatingActionButton(
                  heroTag: 'service_picker_add_service_fab',
                  onPressed: _openCreateServiceForm,
                  backgroundColor: AppColors.lacosPurple,
                  foregroundColor: AppColors.onPrimary,
                  child: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: AppRadius.borderLg,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderSm,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.purple700,
        iconSize: AppIconSizes.md,
        tooltip: tooltip,
      ),
    );
  }
}

class _ServicePickerTile extends StatelessWidget {
  const _ServicePickerTile({
    required this.service,
    required this.onTap,
    required this.onMenuTap,
  });

  final Service service;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = formatServiceDetails(
      durationMinutes: service.durationMinutes,
      price: service.price,
    );

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.borderMd,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.xxxs,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      const _ServiceLeadingIcon(),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.graphite,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (details.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxxs),
                              Text(
                                details,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.more_vert_rounded),
              color: AppColors.textSecondary.withValues(alpha: 0.65),
              iconSize: AppIconSizes.sm,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.lg,
                minHeight: AppSpacing.lg,
              ),
              tooltip: AppStrings.serviceActions,
            ),
            const SizedBox(width: AppSpacing.xxxs),
          ],
        ),
      ),
    );
  }
}

class _ServiceLeadingIcon extends StatelessWidget {
  const _ServiceLeadingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.purple50,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.content_cut_rounded,
        color: AppColors.purple700,
        size: AppIconSizes.sm,
      ),
    );
  }
}

class _ServicePickerEmptyState extends StatelessWidget {
  const _ServicePickerEmptyState({
    required this.onNewServiceTap,
    required this.bottomPadding,
  });

  final VoidCallback onNewServiceTap;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding.copyWith(bottom: bottomPadding),
      children: [
        const HomeEmptyState(
          icon: Icons.content_cut_rounded,
          title: AppStrings.servicePickerEmptyTitle,
          message: AppStrings.servicePickerEmptyMessage,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: AppStrings.servicePickerNewService,
          onPressed: onNewServiceTap,
        ),
      ],
    );
  }
}

class _ServicePickerErrorState extends StatelessWidget {
  const _ServicePickerErrorState({
    required this.message,
    required this.onRetry,
    required this.bottomPadding,
  });

  final String message;
  final VoidCallback onRetry;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.screenPadding.copyWith(bottom: bottomPadding),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                onPressed: onRetry,
                child: const Text(AppStrings.tryAgain),
              ),
            ],
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
