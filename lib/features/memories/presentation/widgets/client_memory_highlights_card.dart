import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_profile_preview.dart';
import 'package:lacos_app/features/memories/application/policies/client_memory_availability_policy.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_highlights.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/presentation/controllers/client_memory_preview_cycle_controller.dart';

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

class ClientMemoryHighlightsPreviewCard extends StatefulWidget {
  const ClientMemoryHighlightsPreviewCard({
    required this.preview,
    required this.onViewAll,
    this.rotationInterval = AppDurations.memoryPreviewRotation,
    this.transitionDuration = AppDurations.memoryPreviewTransition,
    super.key,
  });

  final ClientMemoryProfilePreview preview;
  final VoidCallback onViewAll;
  final Duration rotationInterval;
  final Duration transitionDuration;

  @override
  State<ClientMemoryHighlightsPreviewCard> createState() =>
      _ClientMemoryHighlightsPreviewCardState();
}

class _ClientMemoryHighlightsPreviewCardState
    extends State<ClientMemoryHighlightsPreviewCard>
    with WidgetsBindingObserver {
  late ClientMemoryPreviewCycleController _cycle;
  Timer? _timer;
  bool _isAppActive = true;
  int _slideDirection = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cycle = ClientMemoryPreviewCycleController(
      itemIds: _itemIds(widget.preview),
    );
    _configureTimer();
  }

  @override
  void didUpdateWidget(ClientMemoryHighlightsPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIds = _itemIds(oldWidget.preview);
    final newIds = _itemIds(widget.preview);
    if (!_sameIds(oldIds, newIds)) {
      setState(() {
        _cycle.updateItems(newIds);
      });
      _configureTimer();
      return;
    }

    if (oldWidget.rotationInterval != widget.rotationInterval) {
      _configureTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isAppActive) {
          _isAppActive = true;
          _configureTimer();
        }
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_isAppActive) {
          _isAppActive = false;
          _cancelTimer();
        }
    }
  }

  List<String> _itemIds(ClientMemoryProfilePreview preview) {
    return preview.items
        .map((memory) => memory.id ?? memory.content)
        .toList(growable: false);
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _configureTimer() {
    _cancelTimer();

    if (!_isAppActive || !_cycle.shouldAutoRotate) {
      return;
    }

    _timer = Timer.periodic(widget.rotationInterval, (_) {
      if (!mounted || !_isAppActive) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      _advance(direction: 1);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _advance({required int direction}) {
    final changed = direction >= 0 ? _cycle.advance() : _cycle.goToPrevious();
    if (!changed || !mounted) return;

    setState(() {
      _slideDirection = direction >= 0 ? 1 : -1;
    });
  }

  void _onManualNext() {
    if (!_cycle.hasMultipleItems) return;
    _advance(direction: 1);
    _configureTimer();
  }

  void _onManualPrevious() {
    if (!_cycle.hasMultipleItems) return;
    _advance(direction: -1);
    _configureTimer();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_cycle.hasMultipleItems) return;

    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 120) return;

    // Swipe left → next; swipe right → previous.
    if (velocity < 0) {
      _onManualNext();
    } else {
      _onManualPrevious();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.preview.hasContent) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final items = widget.preview.items;
    final index = _cycle.currentIndex.clamp(0, items.length - 1);
    final currentMemory = items[index];
    final showPinnedIcon =
        widget.preview.kind == ClientMemoryProfilePreviewKind.pinned;
    final showPosition = _cycle.hasMultipleItems;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final transitionDuration = reduceMotion
        ? Duration.zero
        : widget.transitionDuration;

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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Semantics(
            label: currentMemory.content,
            child: AnimatedSwitcher(
              duration: transitionDuration,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topLeft,
                  children: <Widget>[
                    ...previousChildren,
                    ?currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                if (reduceMotion) return child;

                final offsetAnimation = Tween<Offset>(
                  begin: Offset(0, 0.12 * _slideDirection),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: _PreviewLine(
                key: ValueKey(currentMemory.id ?? currentMemory.content),
                memory: currentMemory,
                showPinnedIcon: showPinnedIcon,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            if (showPosition)
              Expanded(
                child: Semantics(
                  label: AppStrings.memoryImportantPositionSemantics(
                    index + 1,
                    items.length,
                  ),
                  excludeSemantics: true,
                  child: Text(
                    AppStrings.memoryImportantPosition(
                      index + 1,
                      items.length,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            Semantics(
              button: true,
              label: AppStrings.memoryImportantViewAll,
              child: TextButton(
                onPressed: widget.onViewAll,
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
  const _PreviewLine({
    required this.memory,
    required this.showPinnedIcon,
    super.key,
  });

  final ClientMemory memory;
  final bool showPinnedIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
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
              maxLines: 3,
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
