import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/domain/exceptions/photo_upload_exception.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';

class UpdateProfessionalController
    extends StateNotifier<AsyncValue<Professional?>> {
  UpdateProfessionalController(this._repository) : super(const AsyncData(null));

  final ProfessionalRepository _repository;

  void reset() {
    state = const AsyncData(null);
  }

  Future<Professional?> updateProfessional({
    required String professionalId,
    required String name,
    String? specialties,
    String? photoPath,
    bool removePhoto = false,
  }) async {
    if (state.isLoading) return null;

    final trimmedId = professionalId.trim();
    final professionalName = name.trim();
    final professionalSpecialties = specialties?.trim();

    if (trimmedId.isEmpty) {
      return _fail(AppStrings.professionalProfileUpdateError);
    }

    if (professionalName.isEmpty) {
      return _fail(AppStrings.professionalProfileNameRequired);
    }

    state = const AsyncLoading();

    try {
      final professional = await _repository.update(
        professionalId: trimmedId,
        name: professionalName,
        specialties: professionalSpecialties?.isEmpty == true
            ? null
            : professionalSpecialties,
        photoPath: photoPath,
        removePhoto: removePhoto,
      );
      state = AsyncData(professional);
      return professional;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }

  Professional? _fail(String message) {
    state = AsyncError(FormatException(message), StackTrace.current);
    return null;
  }
}

String _resolveErrorMessage(Object error) {
  return switch (error) {
    PhotoUploadException() => AppValidationMessages.clientPhotoUploadFailed,
    FormatException(message: final message) => message,
    StateError(message: final message) when message.contains('salão') =>
      message,
    _ => AppStrings.professionalProfileUpdateError,
  };
}
