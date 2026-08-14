import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_header.dart';
import 'package:lacos_app/features/salon/application/providers/salon_providers.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class SalonFormBottomSheet extends ConsumerStatefulWidget {
  const SalonFormBottomSheet({required this.salon, super.key});

  static const nameFieldKey = Key('salon-form-name');
  static const phoneFieldKey = Key('salon-form-phone');
  static const addressFieldKey = Key('salon-form-address');
  static const cityFieldKey = Key('salon-form-city');
  static const stateFieldKey = Key('salon-form-state');
  static const saveButtonKey = Key('salon-form-save');

  final Salon salon;

  @override
  ConsumerState<SalonFormBottomSheet> createState() =>
      _SalonFormBottomSheetState();
}

class _SalonFormBottomSheetState extends ConsumerState<SalonFormBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  String? _nameError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.salon.name);
    _phoneController = TextEditingController(
      text: formatBrazilianPhone(widget.salon.phone ?? ''),
    );
    _addressController = TextEditingController(
      text: widget.salon.address ?? '',
    );
    _cityController = TextEditingController(text: widget.salon.city ?? '');
    _stateController = TextEditingController(text: widget.salon.state ?? '');
    _nameController.addListener(_handleNameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(updateSalonControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_handleNameChanged)
      ..dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (_nameError != null && _nameController.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  bool _validate() {
    final invalidName = _nameController.text.trim().isEmpty;
    setState(() {
      _nameError = invalidName ? AppValidationMessages.salonNameRequired : null;
      _saveError = null;
    });
    return !invalidName;
  }

  Future<void> _save() async {
    if (ref.read(updateSalonControllerProvider).isLoading || !_validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final updated = await ref
        .read(updateSalonControllerProvider.notifier)
        .updateSalon(
          salonId: widget.salon.id,
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          city: _cityController.text,
          stateCode: _stateController.text,
        );
    if (!mounted) return;
    if (updated != null) {
      Navigator.of(context).pop(updated);
      return;
    }
    final error = ref.read(updateSalonControllerProvider).error;
    setState(() {
      _saveError = switch (error) {
        FormatException(message: final message) => message,
        _ => AppStrings.salonUpdateError,
      };
    });
  }

  void _close() {
    if (!ref.read(updateSalonControllerProvider).isLoading) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(updateSalonControllerProvider).isLoading;

    return PopScope(
      canPop: !isLoading,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.9,
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
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    const AppointmentBottomSheetHandle(),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: AppSpacing.screenPadding.copyWith(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppointmentFormHeader(
                              title: AppStrings.salonEditTitle,
                              onClose: isLoading ? null : _close,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              key: SalonFormBottomSheet.nameFieldKey,
                              label: AppStrings.salonNameLabel,
                              hint: AppStrings.salonNameHint,
                              helperText: AppStrings.required,
                              controller: _nameController,
                              enabled: !isLoading,
                              errorText: _nameError,
                              maxLength: AppFieldLimits.salonName,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(Icons.storefront_outlined),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              key: SalonFormBottomSheet.phoneFieldKey,
                              label: AppStrings.salonPhoneLabel,
                              hint: AppStrings.clientPhoneHint,
                              helperText: AppStrings.optional,
                              controller: _phoneController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: const [
                                BrazilianPhoneInputFormatter(),
                              ],
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              key: SalonFormBottomSheet.addressFieldKey,
                              label: AppStrings.salonAddressLabel,
                              hint: AppStrings.salonAddressHint,
                              helperText: AppStrings.optional,
                              controller: _addressController,
                              enabled: !isLoading,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              key: SalonFormBottomSheet.cityFieldKey,
                              label: AppStrings.salonCityLabel,
                              hint: AppStrings.salonCityHint,
                              helperText: AppStrings.optional,
                              controller: _cityController,
                              enabled: !isLoading,
                              maxLength: AppFieldLimits.city,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.location_city_outlined,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              key: SalonFormBottomSheet.stateFieldKey,
                              label: AppStrings.salonStateLabel,
                              hint: AppStrings.salonStateHint,
                              helperText: AppStrings.optional,
                              controller: _stateController,
                              enabled: !isLoading,
                              maxLength: AppFieldLimits.state,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              prefixIcon: const Icon(Icons.map_outlined),
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
                              key: SalonFormBottomSheet.saveButtonKey,
                              label: AppStrings.salonSaveAction,
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
