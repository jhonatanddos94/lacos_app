import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class AgendaScheduleSkeleton extends StatelessWidget {
  const AgendaScheduleSkeleton({super.key});

  static const _blockColor = AppColors.divider;
  static const _avatarColor = AppColors.purple100;
  static final _chipRadius = BorderRadius.circular(AppRadius.sm);
  static final _iconRadius = BorderRadius.circular(AppRadius.xs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs + 2,
        AppSpacing.sm,
        AppSpacing.xs + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonBlock(width: 38, height: 14),
                SizedBox(height: 4),
                _SkeletonBlock(width: 34, height: 10),
                SizedBox(height: 4),
                _SkeletonBlock(width: 24, height: 8),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _SkeletonCircle(size: 36),
          const SizedBox(width: AppSpacing.xs),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBlock(width: double.infinity, height: 14),
                SizedBox(height: 6),
                _SkeletonBlock(width: 132, height: 10),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          _SkeletonBlock(
            width: 58,
            height: 22,
            borderRadius: _chipRadius,
          ),
          const SizedBox(width: AppSpacing.xxxs),
          _SkeletonBlock(
            width: AppIconSizes.md,
            height: AppIconSizes.md,
            borderRadius: _iconRadius,
          ),
        ],
      ),
    );
  }
}

class AgendaSkeletonList extends StatelessWidget {
  const AgendaSkeletonList({
    required this.bottomPadding,
    this.itemCount = 5,
    super.key,
  });

  final double bottomPadding;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMd,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.level1,
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: itemCount,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.divider.withValues(alpha: 0.55),
            ),
            itemBuilder: (context, index) {
              return const AgendaScheduleSkeleton();
            },
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.sm)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AgendaScheduleSkeleton._blockColor,
        borderRadius: borderRadius,
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AgendaScheduleSkeleton._avatarColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
