import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class ClientHighlightCarousel extends StatefulWidget {
  const ClientHighlightCarousel({
    required this.highlights,
    this.size = 112,
    this.switchInterval = defaultSwitchInterval,
    this.transitionDuration = AppDurations.slow,
    super.key,
  });

  static const defaultSwitchInterval = Duration(seconds: 4);

  final List<ClientHighlight> highlights;
  final double size;
  final Duration switchInterval;
  final Duration transitionDuration;

  @override
  State<ClientHighlightCarousel> createState() =>
      _ClientHighlightCarouselState();
}

class _ClientHighlightCarouselState extends State<ClientHighlightCarousel> {
  Timer? _timer;
  late Duration _activeSwitchInterval;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeSwitchInterval = widget.switchInterval;
    _startTimer();
  }

  @override
  void didUpdateWidget(ClientHighlightCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlights.length != widget.highlights.length ||
        _activeSwitchInterval != widget.switchInterval) {
      _currentIndex = 0;
      _activeSwitchInterval = widget.switchInterval;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.highlights.length < 2) return;

    _timer = Timer.periodic(_activeSwitchInterval, (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.highlights.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.highlights.isEmpty) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    final highlight = widget.highlights[_currentIndex];
    final photoSize = widget.size - AppSpacing.xs;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        duration: widget.transitionDuration,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [...previousChildren, ?currentChild],
          );
        },
        child: switch (highlight.kind) {
          ClientHighlightKind.photo => _ClientPhoto(
            key: const ValueKey('photo'),
            size: photoSize,
          ),
          ClientHighlightKind.memory => _ClientMemory(
            key: ValueKey(highlight.label),
            text: highlight.label,
            width: widget.size,
          ),
        },
      ),
    );
  }
}

class _ClientPhoto extends StatelessWidget {
  const _ClientPhoto({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.purple100,
          border: Border.all(color: AppColors.purple200, width: 3),
        ),
        child: Icon(
          Icons.person_rounded,
          color: AppColors.purple700,
          size: size * 0.5,
        ),
      ),
    );
  }
}

class _ClientMemory extends StatelessWidget {
  const _ClientMemory({required this.text, required this.width, super.key});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.purple50,
          borderRadius: AppRadius.borderMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.purple700,
              size: 20,
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.graphite,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
