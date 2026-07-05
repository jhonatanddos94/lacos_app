import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lacos_app/core/config/app_date_formats.dart';
import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class ClientFormBottomSheet extends ConsumerStatefulWidget {
  const ClientFormBottomSheet({this.client, super.key});

  final Client? client;

  @override
  ConsumerState<ClientFormBottomSheet> createState() =>
      _ClientFormBottomSheetState();
}

class _ClientFormBottomSheetState extends ConsumerState<ClientFormBottomSheet> {
  static const _photoAvatarSize = 96.0;
  static const _cameraContainerSize = 40.0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _instagramController = TextEditingController();
  final _imagePicker = ImagePicker();

  XFile? _selectedPhoto;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientFormControllerProvider.notifier).reset();
    });
  }

  void _initializeFields() {
    final client = widget.client;
    if (client == null) return;

    _nameController.text = client.name;
    _phoneController.text = formatBrazilianPhone(client.phone);

    final birthDate = client.birthDate;
    if (birthDate != null) {
      _birthDateController.text = formatBrazilianDate(birthDate);
    }

    final instagram = client.instagram;
    if (instagram != null && instagram.isNotEmpty) {
      _instagramController.text = instagram;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (ref.read(clientFormControllerProvider).isLoading) return;

    final birthDateInput = _birthDateController.text.trim();
    final birthDate = birthDateInput.isEmpty
        ? null
        : parseBrazilianDate(birthDateInput);

    if (birthDateInput.isNotEmpty && birthDate == null) {
      _showMessage(AppValidationMessages.clientBirthDateInvalid);
      return;
    }

    final client = await ref.read(clientFormControllerProvider.notifier).save(
          initialClient: widget.client,
          name: _nameController.text,
          phone: _phoneController.text,
          birthDate: birthDate,
          instagram: _instagramController.text,
        );

    if (!mounted) return;

    if (client != null) {
      Navigator.of(context).pop(client);
      return;
    }

    final error = ref.read(clientFormControllerProvider).error;
    if (error != null) {
      _showMessage(_resolveErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveErrorMessage(Object error) {
    return switch (error) {
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ =>
        '${AppValidationMessages.unexpectedError} '
            '${AppValidationMessages.tryAgain}',
    };
  }

  Future<void> _choosePhoto() async {
    if (ref.read(clientFormControllerProvider).isLoading) return;

    final supportsCamera = _imagePicker.supportsImageSource(ImageSource.camera);
    final supportsGallery = _imagePicker.supportsImageSource(
      ImageSource.gallery,
    );

    if (!supportsCamera && !supportsGallery) {
      _showMessage(AppValidationMessages.clientPhotoPickerUnavailable);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (supportsCamera)
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text(AppStrings.camera),
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                if (supportsGallery)
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text(AppStrings.gallery),
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? photo;
    try {
      photo = await _imagePicker.pickImage(source: source);
    } on PlatformException {
      _showMessage(AppValidationMessages.clientPhotoPickerUnavailable);
      return;
    } on Object {
      _showMessage(AppValidationMessages.clientPhotoPickerUnavailable);
      return;
    }

    if (photo == null || !mounted) return;

    setState(() => _selectedPhoto = photo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(clientFormControllerProvider);
    final isLoading = state.isLoading;

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderTopLg,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              top: AppSpacing.md,
              bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEditing
                        ? AppStrings.editClientTitle
                        : AppStrings.newClientTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PhotoPlaceholder(
                    isEnabled: !isLoading,
                    photo: _selectedPhoto,
                    onTap: _choosePhoto,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: AppStrings.clientName,
                    hint: AppStrings.clientNameHint,
                    helperText: AppStrings.required,
                    controller: _nameController,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    maxLength: AppFieldLimits.clientName,
                    autofillHints: const [AutofillHints.name],
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: AppStrings.clientPhone,
                    hint: AppStrings.clientPhoneHint,
                    helperText: AppStrings.required,
                    controller: _phoneController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: const [BrazilianPhoneInputFormatter()],
                    autofillHints: const [AutofillHints.telephoneNumber],
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: AppStrings.clientBirthDate,
                    hint: AppDateFormats.brazilianDateInput,
                    controller: _birthDateController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                    inputFormatters: const [BirthDateInputFormatter()],
                    prefixIcon: const Icon(Icons.cake_outlined),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: AppStrings.clientInstagram,
                    hint: AppStrings.clientInstagramHint,
                    controller: _instagramController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    maxLength: AppFieldLimits.clientInstagram,
                    inputFormatters: const [InstagramInputFormatter()],
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    prefixText: '@',
                    onFieldSubmitted: (_) => _saveClient(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: 'comingSoon',
                    decoration: const InputDecoration(
                      labelText: AppStrings.preferredProfessional,
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'comingSoon',
                        child: Text(AppStrings.comingSoon),
                      ),
                    ],
                    onChanged: null,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    AppStrings.preferredProfessionalUnavailable,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: _isEditing ? AppStrings.saveChanges : AppStrings.save,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _saveClient,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({
    required this.isEnabled,
    required this.onTap,
    this.photo,
  });

  final bool isEnabled;
  final XFile? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Opacity(
        opacity: isEnabled ? 1 : 0.6,
        child: InkWell(
          // TODO(upload foto)
          onTap: isEnabled ? onTap : null,
          borderRadius: AppRadius.borderLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _ClientFormBottomSheetState._photoAvatarSize,
                height: _ClientFormBottomSheetState._photoAvatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple50,
                  image: photo == null
                      ? null
                      : DecorationImage(
                          image: FileImage(File(photo!.path)),
                          fit: BoxFit.cover,
                        ),
                ),
                child: photo == null
                    ? Center(
                        child: Container(
                          width:
                              _ClientFormBottomSheetState._cameraContainerSize,
                          height:
                              _ClientFormBottomSheetState._cameraContainerSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.purple100,
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.purple700,
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width:
                              _ClientFormBottomSheetState._cameraContainerSize,
                          height:
                              _ClientFormBottomSheetState._cameraContainerSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lacosPurple,
                            border: Border.all(color: AppColors.surface),
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.onPrimary,
                          ),
                        ),
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.addPhoto,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                AppStrings.optionalWrapped,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
