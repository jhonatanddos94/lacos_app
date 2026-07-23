import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

class MemoryFormController extends StateNotifier<AsyncValue<ClientMemory?>> {
  MemoryFormController(this._repository) : super(const AsyncData(null));

  final ClientMemoryRepository _repository;

  void reset() {
    state = const AsyncData(null);
  }

  Future<ClientMemory?> save({
    required String clientId,
    required String content,
    ClientMemory? initialMemory,
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
      if (initialMemory != null) {
        final memory = await _repository.update(
          initialMemory.copyWith(content: trimmedContent),
        );
        state = AsyncData(memory);
        return memory;
      }

      final memory = await _repository.create(
        ClientMemory.draft(
          clientId: clientId,
          content: trimmedContent,
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

  Future<bool> delete(ClientMemory memory) async {
    if (state.isLoading) return false;

    final memoryId = memory.id;
    if (memoryId == null || memoryId.isEmpty) {
      state = AsyncError(
        FormatException(AppStrings.memoryDeleteError),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncLoading();

    try {
      await _repository.delete(memoryId);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stackTrace) {
      final friendlyError = FormatException(_resolveErrorMessage(error));
      state = AsyncError(friendlyError, stackTrace);
      return false;
    }
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
