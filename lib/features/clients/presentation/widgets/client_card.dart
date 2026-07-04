import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_tag.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({required this.client, super.key});

  static const _avatarSize = 54.0;

  final ClientPreview client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: () {},
        borderRadius: AppRadius.borderMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            boxShadow: AppShadows.level1,
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ClientAvatar(client: client),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.graphite,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          client.lastAppointmentDate,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxxs),

                    Text(
                      client.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxs),

                    // Memória principal (agora com maior destaque)
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.purple700,
                        ),
                        const SizedBox(width: AppSpacing.xxxs),
                        Expanded(
                          child: Text(
                            client.memoryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.purple800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxxs),

                    // Informação secundária
                    ClientTag(
                      icon: Icons.favorite_rounded,
                      label: client.sinceLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xxxs),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: AppIconSizes.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.client});

  final ClientPreview client;

  @override
  Widget build(BuildContext context) {
    final initial = client.name.isEmpty ? 'L' : client.name.substring(0, 1);

    return SizedBox(
      width: ClientCard._avatarSize,
      height: ClientCard._avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: ClientCard._avatarSize / 2,
            backgroundColor: AppColors.purple100,
            child: Text(
              initial,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.purple800,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (client.isFavorite)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lacosPurple,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.onPrimary,
                  size: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
