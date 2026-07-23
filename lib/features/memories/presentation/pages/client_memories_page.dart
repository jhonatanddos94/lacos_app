import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_filters.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_visibility_filter.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_actions_bottom_sheet.dart';
import 'package:lacos_app/features/memories/presentation/helpers/client_memory_filters_sheet_host.dart';
import 'package:lacos_app/features/memories/presentation/helpers/memory_form_sheet_host.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_empty_state.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_error_state.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_filtered_empty_state.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_header.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_summary_card.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memory_card.dart';
import 'package:lacos_app/features/memories/presentation/widgets/memory_archive_dialog.dart';

class ClientMemoriesPage extends ConsumerStatefulWidget {
  const ClientMemoriesPage({required this.client, super.key});

  final Client client;

  @override
  ConsumerState<ClientMemoriesPage> createState() => _ClientMemoriesPageState();
}

class _ClientMemoriesPageState extends ConsumerState<ClientMemoriesPage> {
  static const _fabSize = 56.0;
  static const _headerContentHeight =
      AppSpacing.xs + AppSpacing.sm + AppIconSizes.lg + AppSpacing.xs;

  static const _headerGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.purple600, AppColors.purple700, AppColors.lacosPurple],
      stops: [0, 0.45, 1],
    ),
  );

  static const _systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.warmWhite,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  Client get _client => widget.client;

  Future<void> _openFiltersSheet() async {
    final currentFilters = ref.read(clientMemoryFiltersProvider(_client.id));
    final appliedFilters = await showClientMemoryFiltersBottomSheet(
      context: context,
      initialFilters: currentFilters,
    );

    if (!mounted || appliedFilters == null) return;

    ref.read(clientMemoryFiltersProvider(_client.id).notifier).state =
        appliedFilters;
  }

  void _clearFilters() {
    ref.read(clientMemoryFiltersProvider(_client.id).notifier).state =
        ClientMemoryFilters.defaults;
  }

  Future<void> _openCreateMemorySheet() async {
    final memory = await showMemoryFormBottomSheet(
      context: context,
      clientId: _client.id,
    );

    if (!mounted || memory == null) return;

    ref.invalidate(clientMemoriesCatalogProvider(_client.id));
    _showMessage(AppStrings.memorySavedSuccess);
  }

  Future<void> _openEditMemorySheet(ClientMemory memory) async {
    final updatedMemory = await showMemoryFormBottomSheet(
      context: context,
      clientId: _client.id,
      memory: memory,
    );

    if (!mounted || updatedMemory == null) return;

    ref.invalidate(clientMemoriesCatalogProvider(_client.id));
    _showMessage(AppStrings.memoryUpdatedSuccess);
  }

  Future<void> _openMemoryActions(ClientMemory memory) async {
    final action = await showModalBottomSheet<MemoryAction>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => MemoryActionsBottomSheet(
        isPinned: memory.isPinned,
        isArchived: memory.isArchived,
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case MemoryAction.edit:
        await _openEditMemorySheet(memory);
      case MemoryAction.pin:
        await _togglePin(memory, isPinned: true);
      case MemoryAction.unpin:
        await _togglePin(memory, isPinned: false);
      case MemoryAction.archive:
        await _confirmArchiveMemory(memory);
      case MemoryAction.restore:
        await _restoreMemory(memory);
    }
  }

  Future<void> _restoreMemory(ClientMemory memory) async {
    final actionsState = ref.read(clientMemoryActionsControllerProvider);
    if (actionsState.isLoading) return;

    final restored = await ref
        .read(clientMemoryActionsControllerProvider.notifier)
        .restore(memory);

    if (!mounted) return;

    if (restored != null) {
      ref.invalidate(clientMemoriesCatalogProvider(_client.id));
      ref.invalidate(clientMemoriesProvider(_client.id));
      _showMessage(AppStrings.memoryRestoredSuccess);
      return;
    }

    final errorMessage = ref
        .read(clientMemoryActionsControllerProvider)
        .errorMessage;
    if (errorMessage != null) {
      _showMessage(errorMessage);
    }
  }

  Future<void> _togglePin(ClientMemory memory, {required bool isPinned}) async {
    final memoryId = memory.id;
    if (memoryId == null || memoryId.isEmpty) return;

    final actionsState = ref.read(clientMemoryActionsControllerProvider);
    if (actionsState.isLoading) return;

    final updated = await ref
        .read(clientMemoryActionsControllerProvider.notifier)
        .setPinned(memory: memory, isPinned: isPinned);

    if (!mounted) return;

    if (updated != null) {
      ref.invalidate(clientMemoriesCatalogProvider(_client.id));
      _showMessage(
        isPinned
            ? AppStrings.memoryPinnedSuccess
            : AppStrings.memoryUnpinnedSuccess,
      );
      return;
    }

    final errorMessage = ref
        .read(clientMemoryActionsControllerProvider)
        .errorMessage;
    if (errorMessage != null) {
      _showMessage(errorMessage);
    }
  }

  Future<void> _confirmArchiveMemory(ClientMemory memory) async {
    final archived = await showDialog<bool>(
      context: context,
      builder: (context) => MemoryArchiveDialog(memory: memory),
    );

    if (!mounted || archived != true) return;

    ref.invalidate(clientMemoriesCatalogProvider(_client.id));
    _showMessage(AppStrings.memoryArchivedSuccess);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _retryLoadMemories() {
    ref.invalidate(clientMemoriesCatalogProvider(_client.id));
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(clientMemoriesCatalogProvider(_client.id));
    final filteredAsync = ref.watch(filteredClientMemoriesProvider(_client.id));
    final filters = ref.watch(clientMemoryFiltersProvider(_client.id));
    final catalog = catalogAsync.value ?? const [];
    final filteredMemories = filteredAsync.value ?? const [];
    final showFab = catalogAsync.hasValue && catalog.isNotEmpty;
    final topInset = MediaQuery.paddingOf(context).top;
    final headerBackgroundHeight =
        topInset + _headerContentHeight + AppRadius.lg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemOverlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.warmWhite,
        floatingActionButton: showFab
            ? FloatingActionButton(
                heroTag: 'client_memories_fab',
                onPressed: _openCreateMemorySheet,
                backgroundColor: AppColors.lacosPurple,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                child: const Icon(Icons.add_rounded, size: AppIconSizes.lg),
              )
            : null,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerBackgroundHeight,
              child: const DecoratedBox(decoration: _headerGradient),
            ),
            Column(
              children: [
                ClientMemoriesHeader(
                  onBack: () => context.pop(),
                  onFilterTap: _openFiltersSheet,
                  showFilterIndicator: filters.hasActiveFilters,
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.warmWhite,
                      borderRadius: AppRadius.borderTopLg,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.borderTopLg,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: AppSpacing.screenPadding.copyWith(
                                top: AppSpacing.xs,
                                bottom: AppSpacing.sm,
                              ),
                              child: ClientMemoriesSummaryCard(client: _client),
                            ),
                            Expanded(
                              child: catalogAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (_, _) => ClientMemoriesErrorState(
                                  onRetry: _retryLoadMemories,
                                ),
                                data: (_) {
                                  if (catalog.isEmpty) {
                                    return ClientMemoriesEmptyState(
                                      onAddMemory: _openCreateMemorySheet,
                                    );
                                  }

                                  if (filteredMemories.isEmpty) {
                                    return ClientMemoriesFilteredEmptyState(
                                      onClearFilters: _clearFilters,
                                    );
                                  }

                                  return ListView.separated(
                                    padding: AppSpacing.screenPadding.copyWith(
                                      top: 0,
                                      bottom:
                                          AppSpacing.lg +
                                          _fabSize +
                                          AppSpacing.sm,
                                    ),
                                    itemCount: filteredMemories.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: AppSpacing.xxxs),
                                    itemBuilder: (context, index) {
                                      final memory = filteredMemories[index];
                                      return ClientMemoryCard(
                                        memory: memory,
                                        emphasizeArchivedState:
                                            filters.visibility ==
                                            ClientMemoryVisibilityFilter
                                                .archived,
                                        onMenuTap: () =>
                                            _openMemoryActions(memory),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
