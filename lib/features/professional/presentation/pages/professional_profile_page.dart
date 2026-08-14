import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/auth/presentation/account/logout_flow.dart';
import 'package:lacos_app/features/professional/application/helpers/professional_provider_invalidation.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/presentation/helpers/professional_profile_form_sheet.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ProfessionalProfilePage extends ConsumerStatefulWidget {
  const ProfessionalProfilePage({super.key});

  static const logoutButtonKey = Key('professional-profile-logout');
  static const editButtonKey = Key('professional-profile-edit');
  static const avatarKey = Key('professional-profile-avatar');
  static const emailKey = Key('professional-profile-email');

  @override
  ConsumerState<ProfessionalProfilePage> createState() =>
      _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState
    extends ConsumerState<ProfessionalProfilePage> {
  var _isOpeningEditor = false;

  Future<void> _openEditor(Professional professional) async {
    if (_isOpeningEditor) return;

    _isOpeningEditor = true;
    try {
      final updated = await showProfessionalProfileFormBottomSheet(
        context,
        professional: professional,
      );
      if (!mounted || updated == null) return;

      invalidateProfessionalSources(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.professionalProfileUpdatedSuccess),
        ),
      );
    } finally {
      _isOpeningEditor = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceState = ref.watch(workspaceProvider);
    final workspace = workspaceState.valueOrNull;
    final professional = workspace?.professional;
    final email = workspace?.user.email;
    final specialties = professional?.specialties?.trim();
    final name = professional?.name ?? AppStrings.homeDefaultProfessionalName;
    final showLoading = workspaceState.isLoading && !workspaceState.hasValue;
    final showError = workspaceState.hasError && !workspaceState.hasValue;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.graphite,
        elevation: 0,
        title: Text(
          AppStrings.profile,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: showLoading
            ? const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : SingleChildScrollView(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showError) ...[
                      Text(
                        AppStrings.temporaryLoadError,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: AppStrings.tryAgain,
                        variant: AppButtonVariant.text,
                        onPressed: () => ref.invalidate(workspaceProvider),
                      ),
                    ] else ...[
                      _ProfileIdentity(name: name, specialties: specialties),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        AppStrings.professionalProfileProfessionalSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ProfileField(
                        label: AppStrings.professionalProfileNameLabel,
                        value: name,
                      ),
                      if (specialties != null && specialties.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _ProfileField(
                          label: AppStrings.professionalProfileSpecialtiesLabel,
                          value: specialties,
                        ),
                      ],
                      if (professional != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          key: ProfessionalProfilePage.editButtonKey,
                          label: AppStrings.professionalProfileEditAction,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _openEditor(professional),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        AppStrings.professionalProfileAccountSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _ProfileField(
                          key: ProfessionalProfilePage.emailKey,
                          label: AppStrings.professionalProfileEmailLabel,
                          value: email,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        key: ProfessionalProfilePage.logoutButtonKey,
                        label: AppStrings.logout,
                        variant: AppButtonVariant.outline,
                        onPressed: () => confirmLogout(context),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.name, this.specialties});

  final String name;
  final String? specialties;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = name.split(' ').first;
    final initial = firstName.isEmpty ? 'L' : firstName.substring(0, 1);

    return Column(
      children: [
        Semantics(
          label: AppStrings.professionalProfileAvatarSemantics(name),
          child: Container(
            key: ProfessionalProfilePage.avatarKey,
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple100,
            ),
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  initial.toUpperCase(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.purple800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (specialties != null && specialties!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxxs),
          Text(
            specialties!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value, super.key});

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
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
