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
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_actions_bottom_sheet.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_form_bottom_sheet.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_empty_state.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_error_state.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_header.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_summary_card.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memory_card.dart';
import 'package:lacos_app/features/memories/presentation/widgets/memory_delete_dialog.dart';

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
      colors: [
        AppColors.purple600,
        AppColors.purple700,
        AppColors.lacosPurple,
      ],
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

  Future<void> _openCreateMemorySheet() async {
    final memory = await showModalBottomSheet<ClientMemory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => MemoryFormBottomSheet(clientId: _client.id),
    );

    if (!mounted || memory == null) return;

    ref.invalidate(clientMemoriesProvider(_client.id));
    _showMessage(AppStrings.memorySavedSuccess);
  }

  Future<void> _openEditMemorySheet(ClientMemory memory) async {
    final updatedMemory = await showModalBottomSheet<ClientMemory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => MemoryFormBottomSheet(
        clientId: _client.id,
        memory: memory,
      ),
    );

    if (!mounted || updatedMemory == null) return;

    ref.invalidate(clientMemoriesProvider(_client.id));
    _showMessage(AppStrings.memoryUpdatedSuccess);
  }

  Future<void> _openMemoryActions(ClientMemory memory) async {
    final action = await showModalBottomSheet<MemoryAction>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const MemoryActionsBottomSheet(),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case MemoryAction.edit:
        await _openEditMemorySheet(memory);
      case MemoryAction.delete:
        await _confirmDeleteMemory(memory);
    }
  }

  Future<void> _confirmDeleteMemory(ClientMemory memory) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => MemoryDeleteDialog(memory: memory),
    );

    if (!mounted || deleted != true) return;

    ref.invalidate(clientMemoriesProvider(_client.id));
    _showMessage(AppStrings.memoryDeletedSuccess);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _retryLoadMemories() {
    ref.invalidate(clientMemoriesProvider(_client.id));
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(clientMemoriesProvider(_client.id));
    final memories = memoriesAsync.value ?? const [];
    final showFab = memoriesAsync.hasValue && memories.isNotEmpty;
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
              child: const DecoratedBox(
                decoration: _headerGradient,
              ),
            ),
            Column(
              children: [
                ClientMemoriesHeader(onBack: () => context.pop()),
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
                              child: ClientMemoriesSummaryCard(
                                client: _client,
                              ),
                            ),
                            Expanded(
                              child: memoriesAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (_, _) => ClientMemoriesErrorState(
                                  onRetry: _retryLoadMemories,
                                ),
                                data: (loadedMemories) =>
                                    loadedMemories.isEmpty
                                        ? ClientMemoriesEmptyState(
                                            onAddMemory:
                                                _openCreateMemorySheet,
                                          )
                                        : ListView.separated(
                                            padding: AppSpacing.screenPadding
                                                .copyWith(
                                              top: 0,
                                              bottom: AppSpacing.lg +
                                                  _fabSize +
                                                  AppSpacing.sm,
                                            ),
                                            itemCount: loadedMemories.length,
                                            separatorBuilder: (_, _) =>
                                                const SizedBox(
                                              height: AppSpacing.xxxs,
                                            ),
                                            itemBuilder: (context, index) {
                                              final memory =
                                                  loadedMemories[index];
                                              return ClientMemoryCard(
                                                memory: memory,
                                                onMenuTap: () =>
                                                    _openMemoryActions(memory),
                                              );
                                            },
                                          ),
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
