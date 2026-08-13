import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class HomeQuickActionsSection extends StatelessWidget {
  const HomeQuickActionsSection({
    required this.onNewAppointment,
    required this.onNewClient,
    required this.onSearchClient,
    super.key,
  });

  static const sectionKey = Key('home-quick-actions');
  static const newAppointmentKey = Key('home-quick-action-appointment');
  static const newClientKey = Key('home-quick-action-client');
  static const searchClientKey = Key('home-quick-action-search-client');

  final VoidCallback onNewAppointment;
  final VoidCallback onNewClient;
  final VoidCallback onSearchClient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.homeQuickActionsTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.purple700,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: QuickActionCard(
                  key: newAppointmentKey,
                  label: AppStrings.homeQuickActionNewAppointment,
                  semanticLabel:
                      AppStrings.homeQuickActionNewAppointmentSemantic,
                  type: QuickActionType.appointment,
                  onTap: onNewAppointment,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: QuickActionCard(
                  key: newClientKey,
                  label: AppStrings.homeQuickActionNewClient,
                  semanticLabel: AppStrings.homeQuickActionNewClientSemantic,
                  type: QuickActionType.client,
                  onTap: onNewClient,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: QuickActionCard(
                  key: searchClientKey,
                  label: AppStrings.homeQuickActionSearchClient,
                  semanticLabel: AppStrings.homeQuickActionSearchClientSemantic,
                  type: QuickActionType.search,
                  onTap: onSearchClient,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    required this.label,
    required this.semanticLabel,
    required this.type,
    required this.onTap,
    super.key,
  });

  static const _iconContainerSize = 48.0;
  static const _iconSize = AppIconSizes.sm;

  final String label;
  final String semanticLabel;
  final QuickActionType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _QuickActionStyle.fromType(type);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: AppColors.graphite,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: style.backgroundColor,
        borderRadius: AppRadius.borderMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderMd,
                boxShadow: AppShadows.level1,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        height: _iconContainerSize,
                        width: _iconContainerSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: style.iconBackgroundColor,
                          ),
                          child: Icon(
                            style.icon,
                            color: style.iconColor,
                            size: _iconSize,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.clip,
                      style: textStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionStyle {
  const _QuickActionStyle({
    required this.icon,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;

  factory _QuickActionStyle.fromType(QuickActionType type) {
    return switch (type) {
      QuickActionType.appointment => const _QuickActionStyle(
        icon: Icons.edit_calendar_outlined,
        backgroundColor: AppColors.purple50,
        iconBackgroundColor: AppColors.lacosPurple,
        iconColor: AppColors.onPrimary,
      ),
      QuickActionType.client => const _QuickActionStyle(
        icon: Icons.person_add_alt_1_outlined,
        backgroundColor: Color(0xFFFFF0F6),
        iconBackgroundColor: Color(0xFFE83E8C),
        iconColor: AppColors.onPrimary,
      ),
      QuickActionType.search => const _QuickActionStyle(
        icon: Icons.search_rounded,
        backgroundColor: Color(0xFFEFF4FF),
        iconBackgroundColor: Color(0xFF4C6FFF),
        iconColor: AppColors.onPrimary,
      ),
    };
  }
}
