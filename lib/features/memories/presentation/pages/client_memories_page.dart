import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_actions_bottom_sheet.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_form_bottom_sheet.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_empty_state.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memory_card.dart';
import 'package:lacos_app/features/memories/presentation/widgets/memory_delete_dialog.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ClientMemoriesPage extends ConsumerStatefulWidget {
  const ClientMemoriesPage({required this.client, super.key});

  final Client client;

  @override
  ConsumerState<ClientMemoriesPage> createState() => _ClientMemoriesPageState();
}

class _ClientMemoriesPageState extends ConsumerState<ClientMemoriesPage> {
  static const _fabSize = 56.0;
  static const _summaryAvatarRadius = 37.0;
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
                _ClientMemoriesHeader(onBack: () => context.pop()),
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
                        child: memoriesAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (_, _) => _ClientMemoriesErrorState(
                            onRetry: _retryLoadMemories,
                          ),
                          data: (loadedMemories) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: AppSpacing.screenPadding.copyWith(
                                  top: AppSpacing.xs,
                                  bottom: AppSpacing.sm,
                                ),
                                child: _ClientMemoriesSummaryCard(
                                  client: _client,
                                  avatarRadius: _summaryAvatarRadius,
                                ),
                              ),
                              Expanded(
                                child: loadedMemories.isEmpty
                                    ? ClientMemoriesEmptyState(
                                        onAddMemory: _openCreateMemorySheet,
                                      )
                                    : ListView.separated(
                                        padding:
                                            AppSpacing.screenPadding.copyWith(
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
                                          final memory = loadedMemories[index];
                                          return ClientMemoryCard(
                                            memory: memory,
                                            onMenuTap: () =>
                                                _openMemoryActions(memory),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientMemoriesHeader extends StatelessWidget {
  const _ClientMemoriesHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.xs,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    AppStrings.clientMemories,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    AppStrings.clientMemoriesSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
            _HeaderIconButton(
              icon: Icons.tune_rounded,
              onPressed: () {
                // TODO(filtros de memórias)
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onPrimary.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.onPrimary,
        iconSize: AppIconSizes.md,
        tooltip: '',
      ),
    );
  }
}

class _ClientMemoriesSummaryCard extends StatelessWidget {
  const _ClientMemoriesSummaryCard({
    required this.client,
    required this.avatarRadius,
  });

  static const _avatarBorderWidth = 3.0;
  static const _nameFontSize = 28.0;
  static const _watermarkOpacity = 0.06;
  static const _watermarkSize = 96.0;

  final Client client;
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.purple100),
        boxShadow: AppShadows.level1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -AppSpacing.sm,
            top: -AppSpacing.xxs,
            bottom: -AppSpacing.xxs,
            child: Opacity(
              opacity: _watermarkOpacity,
              child: Image.asset(
                AppAssets.lacosLogo,
                width: _watermarkSize,
                height: _watermarkSize,
                fit: BoxFit.contain,
                color: AppColors.lacosPurple,
                colorBlendMode: BlendMode.srcIn,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: _avatarBorderWidth,
                      ),
                      boxShadow: AppShadows.level1,
                    ),
                    child: ClientAvatar(
                      name: client.name,
                      photoUrl: client.photoUrl,
                      radius: avatarRadius,
                      backgroundColor: AppColors.purple100,
                      initialTextStyle:
                          theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.purple800,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.purple100.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: _nameFontSize,
                            color: AppColors.lacosPurple,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _ClientSinceChip(
                          label:
                              '${AppStrings.clientSince} '
                              '${_formatMonthYear(
                                client.clientSince ?? client.createdAt,
                              )}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientSinceChip extends StatelessWidget {
  const _ClientSinceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.purple100,
        borderRadius: AppRadius.borderLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.purple700,
            size: 14,
          ),
          const SizedBox(width: AppSpacing.xxxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.purple800,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientMemoriesErrorState extends StatelessWidget {
  const _ClientMemoriesErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.clientMemoriesLoadError,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.graphite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: AppStrings.tryAgain,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

String _formatMonthYear(DateTime date) {
  return '${_monthName(date.month)}/${date.year}';
}

String _monthName(int month) {
  return switch (month) {
    1 => 'Jan',
    2 => 'Fev',
    3 => 'Mar',
    4 => 'Abr',
    5 => 'Mai',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Ago',
    9 => 'Set',
    10 => 'Out',
    11 => 'Nov',
    12 => 'Dez',
    _ => '',
  };
}
