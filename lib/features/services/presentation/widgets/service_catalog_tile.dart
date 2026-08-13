import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/services/application/services/service_catalog_display_formatter.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class ServiceCatalogTile extends StatelessWidget {
  const ServiceCatalogTile({
    required this.service,
    required this.onTap,
    required this.onMenuTap,
    super.key,
  });

  static Key tileKey(String serviceId) =>
      Key('service-catalog-tile-$serviceId');

  static Key menuKey(String serviceId) =>
      Key('service-catalog-tile-menu-$serviceId');

  final Service service;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = ServiceCatalogDisplayFormatter.details(
      durationMinutes: service.durationMinutes,
      price: service.price,
    );

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                key: tileKey(service.id),
                button: true,
                label: ServiceCatalogDisplayFormatter.semantics(
                  name: service.name,
                  durationMinutes: service.durationMinutes,
                  price: service.price,
                ),
                excludeSemantics: true,
                child: InkWell(
                  onTap: onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: kMinInteractiveDimension,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.xxs,
                        AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.graphite,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xxxs),
                            Text(
                              details,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              key: menuKey(service.id),
              onPressed: onMenuTap,
              icon: const Icon(Icons.more_vert_rounded),
              color: AppColors.textSecondary,
              iconSize: AppIconSizes.md,
              tooltip: AppStrings.servicesMenuSemantics(service.name),
              constraints: const BoxConstraints(
                minWidth: kMinInteractiveDimension,
                minHeight: kMinInteractiveDimension,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
