import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/application/providers/clients_providers.dart';
import 'package:lacos_app/features/clients/application/services/client_list_query_service.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_shortcuts_section.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_header.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_list_section.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_search_bar.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_form_bottom_sheet.dart';
import 'package:lacos_app/features/shell/application/providers/app_shell_providers.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  static const searchBarKey = Key('clients-page-search');

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchText = '';
  var _filter = ClientListFilter.all;

  static const _fabSize = 56.0;
  static const _maxContentWidth = 560.0;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    setState(() => _searchText = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchText = '');
  }

  List<Client> _visibleClients(List<Client> clients) {
    return ClientListQueryService.apply(
      clients: clients,
      filter: _filter,
      query: _searchText,
    );
  }

  Future<void> _openCreateClientSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final createdClient = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const ClientFormBottomSheet(),
    );

    if (!context.mounted || createdClient == null) return;

    ref.invalidate(clientsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.clientCreatedSuccess)),
    );
  }

  Future<void> _refreshClients(WidgetRef ref) async {
    ref.invalidate(clientsProvider);
    await ref.read(clientsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = ref.watch(clientShortcutsProvider);
    final clients = ref.watch(clientsProvider);
    final bottomInset = AppSpacing.sm + _fabSize + AppSpacing.md;

    ref.listen<int>(clientsFocusSearchRequestProvider, (previous, next) {
      if (previous == next) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _searchFocusNode.requestFocus();
      });
    });

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xs,
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
                        const ClientsHeader(),
                        const SizedBox(height: AppSpacing.md),
                        ClientsSearchBar(
                          key: ClientsPage.searchBarKey,
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _handleSearchChanged,
                          onClear: _clearSearch,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClientShortcutsSection(
                          shortcuts: shortcuts,
                          selected: _filter,
                          onSelected: (filter) {
                            setState(() => _filter = filter);
                          },
                        ),
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
                        onRefresh: () => _refreshClients(ref),
                        child: clients.when(
                          data: (clients) => ClientsListSection(
                            clients: _visibleClients(clients),
                            bottomPadding: bottomInset,
                            filter: _filter,
                            hasSearchQuery: _searchText.trim().isNotEmpty,
                          ),
                          loading: () =>
                              _ClientsLoadingState(bottomPadding: bottomInset),
                          error: (error, stackTrace) => _ClientsErrorState(
                            message: _resolveErrorMessage(error),
                            bottomPadding: bottomInset,
                            onRetry: () => ref.invalidate(clientsProvider),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: AppSpacing.screenHorizontal,
            bottom: AppSpacing.sm,
            child: FloatingActionButton(
              heroTag: 'clients_fab',
              onPressed: () => _openCreateClientSheet(context, ref),
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

class _ClientsLoadingState extends StatelessWidget {
  const _ClientsLoadingState({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientsErrorState extends StatelessWidget {
  const _ClientsErrorState({
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
    _ => AppStrings.clientsLoadError,
  };
}
