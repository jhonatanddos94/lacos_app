import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_form_bottom_sheet.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_search_bar.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ClientPickerBottomSheet extends ConsumerStatefulWidget {
  const ClientPickerBottomSheet({super.key});

  @override
  ConsumerState<ClientPickerBottomSheet> createState() =>
      _ClientPickerBottomSheetState();
}

class _ClientPickerBottomSheetState
    extends ConsumerState<ClientPickerBottomSheet> {
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

  void _selectClient(Client client) {
    Navigator.of(context).pop(client);
  }

  Future<void> _openCreateClientForm() async {
    final createdClient = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const ClientFormBottomSheet(),
    );

    if (!mounted || createdClient == null) return;

    ref.invalidate(clientsProvider);
    _selectClient(createdClient);
  }

  List<Client> _filterClients(List<Client> clients) {
    final activeClients = clients
        .where((client) => client.isActive)
        .toList(growable: false);

    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) {
      return activeClients;
    }

    final queryDigits = digitsOnly(query);

    return activeClients
        .where((client) {
          final name = client.name.toLowerCase();
          final phone = client.phone.toLowerCase();
          final phoneDigits = digitsOnly(client.phone);
          final instagram = client.instagram?.toLowerCase() ?? '';

          return name.contains(query) ||
              phone.contains(query) ||
              instagram.contains(query) ||
              (queryDigits.isNotEmpty && phoneDigits.contains(queryDigits));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.85;
    final clientsAsync = ref.watch(clientsProvider);

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
                            AppStrings.clientPickerTitle,
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
                      hintText: AppStrings.clientPickerSearchHint,
                    ),
                  ),
                  Expanded(
                    child: clientsAsync.when(
                      data: (clients) {
                        final filteredClients = _filterClients(clients);

                        if (filteredClients.isEmpty) {
                          return _ClientPickerEmptyState(
                            onNewClientTap: _openCreateClientForm,
                            bottomPadding: _listBottomPadding,
                          );
                        }

                        return ListView.separated(
                          padding: AppSpacing.screenPadding.copyWith(
                            top: 0,
                            bottom: _listBottomPadding,
                          ),
                          itemCount: filteredClients.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final client = filteredClients[index];
                            return _ClientPickerTile(
                              client: client,
                              onTap: () => _selectClient(client),
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
                      error: (error, stackTrace) => _ClientPickerErrorState(
                        message: _resolveErrorMessage(error),
                        onRetry: () => ref.invalidate(clientsProvider),
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
                  heroTag: 'client_picker_add_client_fab',
                  onPressed: _openCreateClientForm,
                  backgroundColor: AppColors.lacosPurple,
                  foregroundColor: AppColors.onPrimary,
                  child: const Icon(Icons.person_add_alt_1_rounded),
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

class _ClientPickerTile extends StatelessWidget {
  const _ClientPickerTile({required this.client, required this.onTap});

  final Client client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              ClientAvatar(
                name: client.name,
                photoUrl: client.photoUrl,
                radius: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(
                      formatBrazilianPhone(client.phone),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                size: AppIconSizes.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientPickerEmptyState extends StatelessWidget {
  const _ClientPickerEmptyState({
    required this.onNewClientTap,
    required this.bottomPadding,
  });

  final VoidCallback onNewClientTap;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding.copyWith(bottom: bottomPadding),
      children: [
        const HomeEmptyState(
          icon: Icons.groups_2_outlined,
          title: AppStrings.clientPickerEmptyTitle,
          message: AppStrings.clientPickerEmptyMessage,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: AppStrings.clientPickerNewClient,
          onPressed: onNewClientTap,
        ),
      ],
    );
  }
}

class _ClientPickerErrorState extends StatelessWidget {
  const _ClientPickerErrorState({
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
    _ => AppStrings.clientsLoadError,
  };
}
