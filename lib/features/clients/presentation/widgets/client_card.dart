import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({required this.client, this.onTap, super.key});

  static const _avatarSize = 54.0;
  static const favoriteIconKey = Key('client-card-favorite');

  final Client client;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
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
                        if (client.isFavorite) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          const ExcludeSemantics(
                            child: Icon(
                              key: favoriteIconKey,
                              Icons.favorite_rounded,
                              color: AppColors.softRose,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxxs),
                    Text(
                      _formatPhone(client.phone),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxs),
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
                            _memoryLabel(client),
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

  final Client client;

  @override
  Widget build(BuildContext context) {
    return ClientAvatar(
      name: client.name,
      photoUrl: client.photoUrl,
      radius: ClientCard._avatarSize / 2,
    );
  }
}

String _formatPhone(String phone) {
  final digits = digitsOnly(phone);
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-'
        '${digits.substring(6)}';
  }

  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-'
        '${digits.substring(7)}';
  }

  return phone;
}

String _memoryLabel(Client client) {
  final instagram = client.instagram;
  if (instagram != null && instagram.isNotEmpty) {
    return '@$instagram';
  }

  final birthDate = client.birthDate;
  if (birthDate != null) {
    return '${AppStrings.clientBirthday}: ${_dayMonthDate(birthDate)}';
  }

  return AppStrings.clientNoMemory;
}

String _dayMonthDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}
