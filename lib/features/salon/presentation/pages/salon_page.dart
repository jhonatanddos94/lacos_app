import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';

class SalonPage extends ConsumerWidget {
  const SalonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salon = ref.watch(workspaceProvider).valueOrNull?.salon;
    final addressParts = [
      salon?.address,
      salon?.city,
      salon?.state,
    ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty);

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
        child: ListView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.lg,
          ),
          children: [
            Text(
              salon?.name ?? AppStrings.homeDefaultSalonName,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SalonField(
              label: AppStrings.salonNameLabel,
              value: salon?.name ?? AppStrings.homeDefaultSalonName,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SalonField(
              label: AppStrings.salonResponsibleLabel,
              value:
                  salon?.responsibleName ??
                  AppStrings.homeDefaultProfessionalName,
            ),
            if (salon?.phone != null && salon!.phone!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _SalonField(label: AppStrings.salonPhoneLabel, value: salon.phone!.trim()),
            ],
            if (addressParts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _SalonField(
                label: AppStrings.salonAddressLabel,
                value: addressParts.join(' · '),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalonField extends StatelessWidget {
  const _SalonField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxs),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
