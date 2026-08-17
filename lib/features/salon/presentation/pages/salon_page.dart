import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/salon/application/helpers/salon_provider_invalidation.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/presentation/helpers/salon_form_sheet.dart';
import 'package:lacos_app/features/working_hours/presentation/navigation/working_hours_navigation.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class SalonPage extends ConsumerStatefulWidget {
  const SalonPage({super.key});

  static const pageKey = Key('salon-page');
  static const infoCardKey = Key('salon-info-card');
  static const responsibleFieldKey = Key('salon-responsible-field');
  static const editButtonKey = Key('salon-edit-button');
  static const workingHoursButtonKey = Key('salon-working-hours-button');

  @override
  ConsumerState<SalonPage> createState() => _SalonPageState();
}

class _SalonPageState extends ConsumerState<SalonPage> {
  var _isOpeningEditor = false;

  Future<void> _openEditor(Salon salon) async {
    if (_isOpeningEditor) return;
    _isOpeningEditor = true;
    try {
      final updated = await showSalonFormBottomSheet(context, salon: salon);
      if (!mounted || updated == null) return;
      invalidateSalonSources(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.salonUpdatedSuccess)),
      );
    } finally {
      _isOpeningEditor = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceState = ref.watch(workspaceProvider);
    final salon = workspaceState.valueOrNull?.salon;
    final showLoading = workspaceState.isLoading && !workspaceState.hasValue;
    final showError = workspaceState.hasError && !workspaceState.hasValue;
    final salonName = salon?.name ?? AppStrings.homeDefaultSalonName;
    final addressParts = [salon?.address, salon?.city, salon?.state]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.graphite,
        elevation: 0,
        title: Text(
          AppStrings.mySalon,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: showLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : ListView(
                key: SalonPage.pageKey,
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg,
                ),
                children: [
                  if (showError) ...[
                    Text(
                      AppStrings.temporaryLoadError,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: AppStrings.tryAgain,
                      variant: AppButtonVariant.text,
                      onPressed: () => ref.invalidate(workspaceProvider),
                    ),
                  ] else ...[
                    _SalonIdentity(name: salonName),
                    const SizedBox(height: AppSpacing.lg),
                    _SalonInformationSection(
                      rows: [
                        _SalonInfoRowData(
                          icon: Icons.storefront_outlined,
                          label: AppStrings.salonNameLabel,
                          value: salonName,
                        ),
                        _SalonInfoRowData(
                          key: SalonPage.responsibleFieldKey,
                          icon: Icons.person_outline_rounded,
                          label: AppStrings.salonResponsibleLabel,
                          value:
                              salon?.responsibleName ??
                              AppStrings.homeDefaultProfessionalName,
                        ),
                        if (salon?.phone?.trim().isNotEmpty == true)
                          _SalonInfoRowData(
                            icon: Icons.phone_outlined,
                            label: AppStrings.salonPhoneLabel,
                            value: formatBrazilianPhone(salon!.phone!.trim()),
                          ),
                        if (addressParts.isNotEmpty)
                          _SalonInfoRowData(
                            icon: Icons.location_on_outlined,
                            label: AppStrings.salonAddressLabel,
                            value: addressParts.join(' · '),
                          ),
                      ],
                    ),
                    if (salon != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        key: SalonPage.workingHoursButtonKey,
                        label: AppStrings.workingHoursOpenAction,
                        icon: Icons.schedule_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: workspaceState.valueOrNull?.professional == null
                            ? null
                            : () => openProfessionalWorkingHoursPage(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton(
                        key: SalonPage.editButtonKey,
                        label: AppStrings.salonEditAction,
                        icon: Icons.edit_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _openEditor(salon),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}

class _SalonIdentity extends StatelessWidget {
  const _SalonIdentity({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty ? 'S' : name.trim().substring(0, 1);

    return Semantics(
      label: AppStrings.salonIdentitySemantics(name),
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple100,
            ),
            alignment: Alignment.center,
            child: Text(
              initial.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.purple800,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.graphite,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxs),
          Text(
            AppStrings.moreSalonSubtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalonInformationSection extends StatelessWidget {
  const _SalonInformationSection({required this.rows});

  static const _iconContainerSize = 36.0;

  final List<_SalonInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.salonInformationSection,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.purple700,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        DecoratedBox(
          key: SalonPage.infoCardKey,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.level1,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.borderMd,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  _SalonInfoRow(data: rows[index]),
                  if (index < rows.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                      indent:
                          AppSpacing.sm +
                          _iconContainerSize +
                          AppSpacing.xs,
                      endIndent: AppSpacing.sm,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SalonInfoRowData {
  const _SalonInfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.key,
  });

  final Key? key;
  final IconData icon;
  final String label;
  final String value;
}

class _SalonInfoRow extends StatelessWidget {
  const _SalonInfoRow({required this.data});

  static const _iconContainerSize = 36.0;

  final _SalonInfoRowData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      key: data.key,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _iconContainerSize,
            height: _iconContainerSize,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple50,
              ),
              child: Icon(
                data.icon,
                color: AppColors.purple700,
                size: AppIconSizes.sm,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  data.value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
