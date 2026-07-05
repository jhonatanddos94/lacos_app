import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

class CreateMemoryController extends StateNotifier<AsyncValue<ClientMemory?>> {
  CreateMemoryController(this._repository) : super(const AsyncData(null));

  final ClientMemoryRepository _repository;

  void reset() {
    state = const AsyncData(null);
  }

  Future<ClientMemory?> create({
    required String clientId,
    required String content,
  }) async {
    if (state.isLoading) return null;

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      return _fail(AppStrings.memoryRequired);
    }

    if (trimmedContent.length > AppFieldLimits.memoryContent) {
      return _fail(AppStrings.memoryMaxLengthError);
    }

    state = const AsyncLoading();

    try {
      final memory = await _repository.create(
        ClientMemory(
          clientId: clientId,
          salonId: '',
          ownerId: '',
          content: trimmedContent,
          isActive: true,
        ),
      );
      state = AsyncData(memory);
      return memory;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return null;
    }
  }

  ClientMemory? _fail(String message) {
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
