import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/features/clients/domain/exceptions/client_photo_upload_exception.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';

class ClientFormController extends StateNotifier<AsyncValue<Client?>> {
  ClientFormController(this._repository) : super(const AsyncData(null));

  final ClientRepository _repository;
  var _isMutating = false;

  void reset() {
    state = const AsyncData(null);
  }

  Future<Client?> save({
    Client? initialClient,
    required String name,
    required String phone,
    DateTime? birthDate,
    String? instagram,
    String? photoPath,
  }) async {
    if (_isMutating || state.isLoading) return null;

    final clientName = name.trim();
    final clientPhone = digitsOnly(phone);
    final clientInstagram = instagram == null
        ? null
        : normalizeInstagram(instagram);

    if (clientName.isEmpty) {
      return _fail(AppValidationMessages.clientNameRequired);
    }

    if (clientPhone.isEmpty) {
      return _fail(AppValidationMessages.clientPhoneRequired);
    }

    if (clientPhone.length < 10 || clientPhone.length > 11) {
      return _fail(AppValidationMessages.clientPhoneInvalid);
    }

    _isMutating = true;
    state = const AsyncLoading();

    try {
      final normalizedInstagram = clientInstagram?.isEmpty == true
          ? null
          : clientInstagram;

      if (initialClient != null) {
        final updatedClient = initialClient.copyWith(
          name: clientName,
          phone: clientPhone,
          birthDate: birthDate,
          instagram: normalizedInstagram,
          clearBirthDate: birthDate == null,
          clearInstagram: normalizedInstagram == null,
        );
        final client = await _repository.update(
          updatedClient,
          photoPath: photoPath,
        );
        state = AsyncData(client);
        return client;
      }

      final client = await _repository.create(
        name: clientName,
        phone: clientPhone,
        birthDate: birthDate,
        instagram: normalizedInstagram,
        photoPath: photoPath,
      );
      state = AsyncData(client);
      return client;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    } finally {
      _isMutating = false;
    }
  }

  Future<Client?> setFavorite({
    required Client client,
    required bool isFavorite,
  }) async {
    if (_isMutating || state.isLoading) return null;

    _isMutating = true;

    try {
      final updated = await _repository.update(
        client.copyWith(isFavorite: isFavorite),
      );
      state = AsyncData(updated);
      return updated;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    } finally {
      _isMutating = false;
    }
  }

  Future<bool> delete(Client client) async {
    if (_isMutating || state.isLoading) return false;

    _isMutating = true;
    state = const AsyncLoading();

    try {
      await _repository.delete(client.id);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return false;
    } finally {
      _isMutating = false;
    }
  }

  Client? _fail(String message) {
    state = AsyncError(FormatException(message), StackTrace.current);
    return null;
  }
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
