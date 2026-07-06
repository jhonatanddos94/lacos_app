import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/clients/presentation/widgets/clients_search_bar.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ProfessionalPickerBottomSheet extends ConsumerStatefulWidget {
  const ProfessionalPickerBottomSheet({super.key});

  @override
  ConsumerState<ProfessionalPickerBottomSheet> createState() =>
      _ProfessionalPickerBottomSheetState();
}

class _ProfessionalPickerBottomSheetState
    extends ConsumerState<ProfessionalPickerBottomSheet> {
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    setState(() => _searchText = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchText = '');
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _selectProfessional(Professional professional) {
    Navigator.of(context).pop(professional);
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.professionalPickerNewProfessionalComingSoon),
      ),
    );
  }

  List<Professional> _filterProfessionals(List<Professional> professionals) {
    final activeProfessionals = professionals
        .where((professional) => professional.isActive)
        .toList(growable: false);

    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) {
      return activeProfessionals;
    }

    return activeProfessionals.where((professional) {
      final name = professional.name.toLowerCase();
      final specialties = professional.specialties?.toLowerCase() ?? '';
      final role = professional.role?.toLowerCase() ?? '';

      return name.contains(query) ||
          specialties.contains(query) ||
          role.contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.85;
    final professionalsAsync = ref.watch(professionalsProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xs),
              const _SheetHandle(),
              Padding(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _HeaderIconButton(
                      icon: Icons.close_rounded,
                      onPressed: _close,
                      tooltip: AppStrings.cancel,
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.professionalPickerTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: AppSpacing.screenPadding.copyWith(
                  top: 0,
                  bottom: AppSpacing.sm,
                ),
                child: ClientsSearchBar(
                  controller: _searchController,
                  onChanged: _handleSearchChanged,
                  onClear: _clearSearch,
                  hintText: AppStrings.professionalPickerSearchHint,
                ),
              ),
              Expanded(
                child: professionalsAsync.when(
                  data: (professionals) {
                    final filteredProfessionals =
                        _filterProfessionals(professionals);

                    if (filteredProfessionals.isEmpty) {
                      return _ProfessionalPickerEmptyState(
                        onNewProfessionalTap: _showComingSoonMessage,
                      );
                    }

                    return ListView.separated(
                      padding: AppSpacing.screenPadding.copyWith(
                        top: 0,
                        bottom: AppSpacing.lg,
                      ),
                      itemCount: filteredProfessionals.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final professional = filteredProfessionals[index];
                        return _ProfessionalPickerTile(
                          professional: professional,
                          onTap: () => _selectProfessional(professional),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                  error: (error, stackTrace) => _ProfessionalPickerErrorState(
                    message: _resolveErrorMessage(error),
                    onRetry: () => ref.invalidate(professionalsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: AppRadius.borderLg,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderSm,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.purple700,
        iconSize: AppIconSizes.md,
        tooltip: tooltip,
      ),
    );
  }
}

class _ProfessionalPickerTile extends StatelessWidget {
  const _ProfessionalPickerTile({
    required this.professional,
    required this.onTap,
  });

  final Professional professional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _formatProfessionalSubtitle(professional);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              ClientAvatar(
                name: professional.name,
                radius: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                size: AppIconSizes.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionalPickerEmptyState extends StatelessWidget {
  const _ProfessionalPickerEmptyState({
    required this.onNewProfessionalTap,
  });

  final VoidCallback onNewProfessionalTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.lg),
      children: [
        const HomeEmptyState(
          icon: Icons.badge_outlined,
          title: AppStrings.professionalPickerEmptyTitle,
          message: AppStrings.professionalPickerEmptyMessage,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: AppStrings.professionalPickerNewProfessionalComingSoon,
          onPressed: onNewProfessionalTap,
        ),
      ],
    );
  }
}

class _ProfessionalPickerErrorState extends StatelessWidget {
  const _ProfessionalPickerErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.lg),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: onRetry,
                child: const Text(AppStrings.tryAgain),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String? _formatProfessionalSubtitle(Professional professional) {
  final specialties = professional.specialties?.trim();
  if (specialties != null && specialties.isNotEmpty) {
    return specialties;
  }

  final role = professional.role?.trim();
  if (role != null && role.isNotEmpty) {
    return role;
  }

  return null;
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) => message,
    StateError(message: final message) => message,
    _ => AppStrings.professionalsLoadError,
  };
}
