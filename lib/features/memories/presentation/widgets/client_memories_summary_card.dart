import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/constants/app_assets.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';

class ClientMemoriesSummaryCard extends StatelessWidget {
  const ClientMemoriesSummaryCard({
    required this.client,
    this.avatarRadius = 37,
    super.key,
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
                      initialTextStyle: theme.textTheme.headlineSmall?.copyWith(
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
                              '${_formatMonthYear(client.clientSince ?? client.createdAt)}',
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
