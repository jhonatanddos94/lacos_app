import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';

class ClientFormController extends StateNotifier<AsyncValue<Client?>> {
  ClientFormController(this._repository) : super(const AsyncData(null));

  final ClientRepository _repository;

  void reset() {
    state = const AsyncData(null);
  }

  Future<Client?> save({
    Client? initialClient,
    required String name,
    required String phone,
    DateTime? birthDate,
    String? instagram,
  }) async {
    if (state.isLoading) return null;

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

    state = const AsyncLoading();

    try {
      final normalizedInstagram =
          clientInstagram?.isEmpty == true ? null : clientInstagram;

      if (initialClient != null) {
        final updatedClient = Client(
          id: initialClient.id,
          name: clientName,
          phone: clientPhone,
          birthDate: birthDate,
          instagram: normalizedInstagram,
          photoUrl: initialClient.photoUrl,
          isActive: initialClient.isActive,
          clientSince: initialClient.clientSince,
          createdAt: initialClient.createdAt,
          updatedAt: initialClient.updatedAt,
        );
        final client = await _repository.update(updatedClient);
        state = AsyncData(client);
        return client;
      }

      final client = await _repository.create(
        name: clientName,
        phone: clientPhone,
        birthDate: birthDate,
        instagram: normalizedInstagram,
      );
      state = AsyncData(client);
      return client;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }

  Client? _fail(String message) {
    state = AsyncError(FormatException(message), StackTrace.current);
    return null;
  }
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
