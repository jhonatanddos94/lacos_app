import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_header.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class ProfessionalProfileFormBottomSheet extends ConsumerStatefulWidget {
  const ProfessionalProfileFormBottomSheet({
    required this.professional,
    super.key,
  });

  static const nameFieldKey = Key('professional-profile-form-name');
  static const specialtiesFieldKey = Key(
    'professional-profile-form-specialties',
  );
  static const saveButtonKey = Key('professional-profile-form-save');

  final Professional professional;

  @override
  ConsumerState<ProfessionalProfileFormBottomSheet> createState() =>
      _ProfessionalProfileFormBottomSheetState();
}

class _ProfessionalProfileFormBottomSheetState
    extends ConsumerState<ProfessionalProfileFormBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _specialtiesController;
  String? _nameError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.professional.name);
    _specialtiesController = TextEditingController(
      text: widget.professional.specialties ?? '',
    );
    _nameController.addListener(_handleNameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(updateProfessionalControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_handleNameChanged)
      ..dispose();
    _specialtiesController.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (_nameError != null && _nameController.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _close() {
    if (ref.read(updateProfessionalControllerProvider).isLoading) return;
    Navigator.of(context).pop();
  }

  bool _validateForm() {
    final hasNameError = _nameController.text.trim().isEmpty;
    setState(() {
      _nameError = hasNameError
          ? AppStrings.professionalProfileNameRequired
          : null;
      _saveError = null;
    });
    return !hasNameError;
  }

  Future<void> _save() async {
    if (ref.read(updateProfessionalControllerProvider).isLoading) return;
    if (!_validateForm()) return;

    final professional = await ref
        .read(updateProfessionalControllerProvider.notifier)
        .updateProfessional(
          professionalId: widget.professional.id,
          name: _nameController.text,
          specialties: _specialtiesController.text,
        );

    if (!mounted) return;

    if (professional != null) {
      Navigator.of(context).pop(professional);
      return;
    }

    final error = ref.read(updateProfessionalControllerProvider).error;
    setState(() {
      _saveError = switch (error) {
        FormatException(message: final message) => message,
        _ => AppStrings.professionalProfileUpdateError,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(updateProfessionalControllerProvider).isLoading;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.72;

    return PopScope(
      canPop: !isLoading,
      child: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: Material(
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
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    const AppointmentBottomSheetHandle(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: AppSpacing.screenPadding.copyWith(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppointmentFormHeader(
                              title: AppStrings.professionalProfileEditTitle,
                              onClose: isLoading ? null : _close,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              key: ProfessionalProfileFormBottomSheet
                                  .nameFieldKey,
                              label: AppStrings.professionalProfileNameLabel,
                              hint: AppStrings.professionalProfileNameHint,
                              helperText: AppStrings.required,
                              controller: _nameController,
                              enabled: !isLoading,
                              errorText: _nameError,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              maxLength: AppFieldLimits.professionalName,
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              key: ProfessionalProfileFormBottomSheet
                                  .specialtiesFieldKey,
                              label: AppStrings
                                  .professionalProfileSpecialtiesLabel,
                              hint:
                                  AppStrings.professionalProfileSpecialtiesHint,
                              helperText: AppStrings.optional,
                              controller: _specialtiesController,
                              enabled: !isLoading,
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.words,
                              maxLength: AppFieldLimits.professionalSpecialties,
                              prefixIcon: const Icon(
                                Icons.content_cut_outlined,
                              ),
                              onFieldSubmitted: (_) => _save(),
                            ),
                            if (_saveError != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _saveError!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            AppButton(
                              key: ProfessionalProfileFormBottomSheet
                                  .saveButtonKey,
                              label: AppStrings.professionalProfileSaveAction,
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _save,
                            ),
                          ],
                        ),
                      ),
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
