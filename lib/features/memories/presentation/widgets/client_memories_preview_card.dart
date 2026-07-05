import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class ClientMemoriesPreviewCard extends StatefulWidget {
  const ClientMemoriesPreviewCard({
    required this.memories,
    this.isLoading = false,
    this.errorMessage,
    this.onTap,
    super.key,
  });

  final List<ClientMemory> memories;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onTap;

  @override
  State<ClientMemoriesPreviewCard> createState() =>
      _ClientMemoriesPreviewCardState();
}

class _ClientMemoriesPreviewCardState extends State<ClientMemoriesPreviewCard> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _configureTimer();
  }

  @override
  void didUpdateWidget(ClientMemoriesPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_shouldResetCarousel(oldWidget)) {
      _resetCarousel();
      return;
    }

    if (oldWidget.isLoading != widget.isLoading ||
        oldWidget.errorMessage != widget.errorMessage) {
      _configureTimer();
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  bool _shouldResetCarousel(ClientMemoriesPreviewCard oldWidget) {
    if (oldWidget.memories.length != widget.memories.length) {
      return true;
    }

    for (var index = 0; index < widget.memories.length; index++) {
      if (oldWidget.memories[index].id != widget.memories[index].id) {
        return true;
      }
    }

    return false;
  }

  void _resetCarousel() {
    if (_currentIndex != 0) {
      if (mounted) {
        setState(() => _currentIndex = 0);
      } else {
        _currentIndex = 0;
      }
    }

    _configureTimer();
  }

  void _configureTimer() {
    _cancelTimer();

    if (widget.isLoading ||
        widget.errorMessage != null ||
        widget.memories.length <= 1) {
      if (_currentIndex != 0) {
        if (mounted) {
          setState(() => _currentIndex = 0);
        } else {
          _currentIndex = 0;
        }
      }
      return;
    }

    _timer = Timer.periodic(AppDurations.memoryPreviewRotation, (_) {
      if (!mounted) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.memories.length;
      });
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.borderMd,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.purple700,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xxxs),
                  Expanded(
                    child: Text(
                      AppStrings.clientMemories,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.graphite,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (widget.isLoading)
                const _MemoriesLoadingBody()
              else if (widget.errorMessage != null)
                _MemoriesErrorBody(message: widget.errorMessage!)
              else if (widget.memories.isEmpty)
                const _MemoriesEmptyBody()
              else
                _MemoriesPreviewBody(
                  currentMemory: widget.memories[_currentIndex],
                  currentIndex: _currentIndex,
                  totalCount: widget.memories.length,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoriesLoadingBody extends StatelessWidget {
  const _MemoriesLoadingBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: AppSpacing.sm,
          height: AppSpacing.sm,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.purple700.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          AppStrings.loading,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MemoriesErrorBody extends StatelessWidget {
  const _MemoriesErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        height: 1.35,
      ),
    );
  }
}

class _MemoriesEmptyBody extends StatelessWidget {
  const _MemoriesEmptyBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.purple50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite_rounded, color: AppColors.purple700),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.clientNoMemoriesTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                AppStrings.clientMemoriesComingSoon,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemoriesPreviewBody extends StatelessWidget {
  const _MemoriesPreviewBody({
    required this.currentMemory,
    required this.currentIndex,
    required this.totalCount,
  });

  final ClientMemory currentMemory;
  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCarouselMeta = totalCount > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: AppDurations.normal,
          child: Column(
            key: ValueKey(currentMemory.id ?? currentIndex),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentMemory.content,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                _formatMemoryDate(currentMemory.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (showCarouselMeta) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _formatMemoriesCount(totalCount),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.purple700,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxs),
          Text(
            _formatMemoryPosition(currentIndex, totalCount),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

String _formatMemoryDate(DateTime? date) {
  if (date == null) return '';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final memoryDate = DateTime(date.year, date.month, date.day);
  final difference = today.difference(memoryDate).inDays;

  if (difference == 0) return 'Hoje';
  if (difference == 1) return 'Ontem';

  return formatBrazilianDate(date);
}

String _formatMemoriesCount(int count) {
  if (count == 1) return '+1 memória registrada';

  return '+$count memórias registradas';
}

String _formatMemoryPosition(int currentIndex, int totalCount) {
  return '${currentIndex + 1} de $totalCount';
}
