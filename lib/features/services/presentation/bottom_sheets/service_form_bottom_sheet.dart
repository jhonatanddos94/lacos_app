import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/core/formatters/service_form_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';
import 'package:lacos_app/features/services/domain/constants/service_categories.dart';
import 'package:lacos_app/features/services/domain/constants/service_duration_options.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class ServiceFormBottomSheet extends ConsumerStatefulWidget {
  const ServiceFormBottomSheet({this.service, super.key});

  final Service? service;

  @override
  ConsumerState<ServiceFormBottomSheet> createState() =>
      _ServiceFormBottomSheetState();
}

class _ServiceFormBottomSheetState extends ConsumerState<ServiceFormBottomSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  int? _selectedDurationMinutes;
  String? _nameError;
  String? _durationError;
  String? _generalError;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _nameController.addListener(_handleNameChanged);
    _descriptionController.addListener(_handleDescriptionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceFormControllerProvider.notifier).reset();
    });
  }

  void _initializeFields() {
    final service = widget.service;
    if (service == null) return;

    _nameController.text = service.name;
    _selectedCategory = service.category;
    _selectedDurationMinutes = service.durationMinutes;

    final price = service.price;
    if (price != null) {
      _priceController.text = formatServicePrice(price);
    }

    final description = service.description;
    if (description != null && description.isNotEmpty) {
      _descriptionController.text = description;
    }
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_handleNameChanged)
      ..dispose();
    _priceController.dispose();
    _descriptionController
      ..removeListener(_handleDescriptionChanged)
      ..dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (_nameError != null && _nameController.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  void _handleDescriptionChanged() {
    setState(() {});
  }

  bool _validateForm() {
    final name = _nameController.text.trim();
    final hasNameError = name.isEmpty;
    final hasDurationError =
        _selectedDurationMinutes == null || _selectedDurationMinutes! <= 0;

    setState(() {
      _nameError =
          hasNameError ? AppValidationMessages.serviceNameRequired : null;
      _durationError = hasDurationError
          ? AppValidationMessages.serviceDurationRequired
          : null;
      _generalError = null;
    });

    return !hasNameError && !hasDurationError;
  }

  void _close() {
    if (ref.read(serviceFormControllerProvider).isLoading) return;
    Navigator.of(context).pop();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveService() async {
    if (ref.read(serviceFormControllerProvider).isLoading) return;

    if (!_validateForm()) return;

    final service = await ref.read(serviceFormControllerProvider.notifier).save(
          initialService: widget.service,
          name: _nameController.text,
          durationMinutes: _selectedDurationMinutes,
          category: _selectedCategory,
          price: parseBrazilianPrice(_priceController.text),
          description: _descriptionController.text,
        );

    if (!mounted) return;

    if (service != null) {
      Navigator.of(context).pop(service);
      return;
    }

    final error = ref.read(serviceFormControllerProvider).error;
    if (error != null) {
      setState(() {
        _generalError = _isEditing
            ? AppStrings.serviceUpdateError
            : AppStrings.serviceSaveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(serviceFormControllerProvider);
    final isLoading = state.isLoading;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.9;
    final descriptionLength = _descriptionController.text.characters.length;

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
                    const _SheetHandle(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: AppSpacing.screenPadding.copyWith(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ServiceFormHeader(
                              isEditing: _isEditing,
                              onClose: _close,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              label: AppStrings.serviceNameLabel,
                              hint: AppStrings.serviceNameHint,
                              helperText: AppStrings.required,
                              controller: _nameController,
                              enabled: !isLoading,
                              errorText: _nameError,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              maxLength: AppFieldLimits.serviceName,
                              prefixIcon:
                                  const Icon(Icons.content_cut_outlined),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<String?>(
                              key: ValueKey(_selectedCategory),
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: AppStrings.serviceCategoryLabel,
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              hint: const Text(AppStrings.serviceCategoryHint),
                              items: [
                                const DropdownMenuItem<String?>(
                                  child: Text(AppStrings.serviceCategoryHint),
                                ),
                                for (final category in ServiceCategories.values)
                                  DropdownMenuItem<String?>(
                                    value: category,
                                    child: Text(category),
                                  ),
                              ],
                              onChanged: isLoading
                                  ? null
                                  : (value) => setState(
                                        () => _selectedCategory = value,
                                      ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<int?>(
                              key: ValueKey(_selectedDurationMinutes),
                              initialValue: _selectedDurationMinutes,
                              decoration: InputDecoration(
                                labelText: AppStrings.serviceDurationLabel,
                                helperText: _durationError == null
                                    ? AppStrings.required
                                    : null,
                                errorText: _durationError,
                                prefixIcon:
                                    const Icon(Icons.schedule_outlined),
                              ),
                              hint: const Text(AppStrings.serviceDurationHint),
                              items: [
                                const DropdownMenuItem<int?>(
                                  child: Text(AppStrings.serviceDurationHint),
                                ),
                                for (final option
                                    in ServiceDurationOptions.values)
                                  DropdownMenuItem<int?>(
                                    value: option.minutes,
                                    child: Text(option.label),
                                  ),
                              ],
                              onChanged: isLoading
                                  ? null
                                  : (value) => setState(() {
                                        _selectedDurationMinutes = value;
                                        if (_durationError != null &&
                                            value != null &&
                                            value > 0) {
                                          _durationError = null;
                                        }
                                      }),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              label: AppStrings.servicePriceLabel,
                              hint: AppStrings.servicePriceHint,
                              controller: _priceController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: const [
                                BrazilianPriceInputFormatter(),
                              ],
                              prefixIcon:
                                  const Icon(Icons.payments_outlined),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Stack(
                              children: [
                                AppTextField(
                                  controller: _descriptionController,
                                  enabled: !isLoading,
                                  label: AppStrings.serviceDescriptionLabel,
                                  hint: AppStrings.serviceDescriptionHint,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 4,
                                  minLines: 3,
                                  maxLength: AppFieldLimits.serviceFormDescription,
                                ),
                                Positioned(
                                  right: AppSpacing.xxs,
                                  bottom: AppSpacing.xxxs,
                                  child: Text(
                                    '$descriptionLength/${AppFieldLimits.serviceFormDescription}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (_generalError != null) ...[
                              Text(
                                _generalError!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            AppButton(
                              label: _isEditing
                                  ? AppStrings.saveChanges
                                  : AppStrings.saveService,
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _saveService,
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

class _ServiceFormHeader extends StatelessWidget {
  const _ServiceFormHeader({
    required this.isEditing,
    required this.onClose,
  });

  final bool isEditing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderIconButton(
          icon: Icons.close_rounded,
          onPressed: onClose,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                isEditing
                    ? AppStrings.editService
                    : AppStrings.newServiceTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                isEditing
                    ? AppStrings.editServiceSubtitle
                    : AppStrings.newServiceSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

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
        tooltip: AppStrings.cancel,
      ),
    );
  }
}
