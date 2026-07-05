import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

final _imagePicker = ImagePicker();

Future<XFile?> pickClientPhoto(
  BuildContext context, {
  void Function(String message)? onMessage,
}) async {
  final supportsCamera = _imagePicker.supportsImageSource(ImageSource.camera);
  final supportsGallery = _imagePicker.supportsImageSource(ImageSource.gallery);

  if (!supportsCamera && !supportsGallery) {
    onMessage?.call(AppValidationMessages.clientPhotoPickerUnavailable);
    return null;
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

  if (source == null) return null;

  try {
    return await _imagePicker.pickImage(source: source);
  } on PlatformException {
    onMessage?.call(AppValidationMessages.clientPhotoPickerUnavailable);
    return null;
  } on Object {
    onMessage?.call(AppValidationMessages.clientPhotoPickerUnavailable);
    return null;
  }
}
