import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lacos_app/core/config/app_validation_messages.dart';

final _imagePicker = ImagePicker();

/// Seleciona foto da galeria para o perfil profissional (V1 — sem câmera).
Future<XFile?> pickProfessionalPhotoFromGallery(
  BuildContext context, {
  void Function(String message)? onMessage,
}) async {
  if (!_imagePicker.supportsImageSource(ImageSource.gallery)) {
    onMessage?.call(AppValidationMessages.clientPhotoPickerUnavailable);
    return null;
  }

  try {
    return await _imagePicker.pickImage(source: ImageSource.gallery);
  } on PlatformException {
    onMessage?.call(AppValidationMessages.clientPhotoPickerUnavailable);
    return null;
  } on Object {
    onMessage?.call(AppValidationMessages.clientPhotoPickerUnavailable);
    return null;
  }
}

typedef ProfessionalPhotoPicker =
    Future<XFile?> Function(
      BuildContext context, {
      void Function(String message)? onMessage,
    });
