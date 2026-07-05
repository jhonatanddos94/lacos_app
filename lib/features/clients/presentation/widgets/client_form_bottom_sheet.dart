import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'package:lacos_app/features/clients/domain/exceptions/client_photo_upload_exception.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_photo_picker.dart';
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
  static const _photoAvatarRadius = 48.0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _instagramController = TextEditingController();

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
          photoPath: _selectedPhoto?.path,
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
      ClientPhotoUploadException() =>
        AppValidationMessages.clientPhotoUploadFailed,
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ =>
        '${AppValidationMessages.unexpectedError} '
            '${AppValidationMessages.tryAgain}',
    };
  }

  Future<void> _choosePhoto() async {
    if (ref.read(clientFormControllerProvider).isLoading) return;

    final photo = await pickClientPhoto(
      context,
      onMessage: _showMessage,
    );

    if (photo == null || !mounted) return;

    setState(() => _selectedPhoto = photo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(clientFormControllerProvider);
    final isLoading = state.isLoading;

    return PopScope(
      canPop: !isLoading,
      child: Material(
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
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClientAvatar(
                          name: widget.client?.name ?? _nameController.text,
                          photoUrl: widget.client?.photoUrl,
                          localPhotoPath: _selectedPhoto?.path,
                          radius: _photoAvatarRadius,
                          showCameraBadge: true,
                          onTap: _choosePhoto,
                          enabled: !isLoading,
                        ),
                        if (_selectedPhoto == null &&
                            (widget.client?.photoUrl == null ||
                                widget.client!.photoUrl!.isEmpty)) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppStrings.tapAvatarToAddPhoto,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
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
    ),
    );
  }
}
