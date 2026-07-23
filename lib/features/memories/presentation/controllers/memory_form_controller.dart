import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/presentation/controllers/memory_form_state.dart';

class MemoryFormController extends StateNotifier<MemoryFormState> {
  MemoryFormController(this._repository) : super(const MemoryFormState());

  final ClientMemoryRepository _repository;
  ClientMemory? _initialMemory;

  void initializeForCreate() {
    _initialMemory = null;
    state = const MemoryFormState();
  }

  void initializeForEdit(ClientMemory memory) {
    _initialMemory = memory;
    state = MemoryFormState(
      content: memory.content,
      type: memory.type,
      priority: memory.priority,
      isPinned: memory.isPinned,
      isEditing: true,
    );
  }

  void reset() {
    _initialMemory = null;
    state = const MemoryFormState();
  }

  void setContent(String value) {
    state = state.copyWith(
      content: value,
      clearContentError: true,
      clearErrorMessage: true,
    );
  }

  void setType(ClientMemoryType type) {
    state = state.copyWith(type: type, clearErrorMessage: true);
  }

  void setPriority(ClientMemoryPriority priority) {
    state = state.copyWith(priority: priority, clearErrorMessage: true);
  }

  void setPinned(bool value) {
    state = state.copyWith(isPinned: value, clearErrorMessage: true);
  }

  Future<ClientMemory?> save({required String clientId}) async {
    if (state.isSubmitting) return null;

    final validationError = _validateContent(state.content);
    if (validationError != null) {
      state = state.copyWith(contentError: validationError);
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      final trimmedContent = state.content.trim();
      final memory = _initialMemory == null
          ? await _repository.create(
              ClientMemory.draft(
                clientId: clientId,
                content: trimmedContent,
              ).copyWith(
                type: state.type,
                priority: state.priority,
                isPinned: state.isPinned,
              ),
            )
          : await _repository.update(
              _initialMemory!.copyWith(
                content: trimmedContent,
                type: state.type,
                priority: state.priority,
                isPinned: state.isPinned,
              ),
            );

      state = state.copyWith(isSubmitting: false);
      return memory;
    } on Object catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _resolveErrorMessage(error),
      );
      return null;
    }
  }

  Future<bool> delete(ClientMemory memory) async {
    if (state.isSubmitting) return false;

    final memoryId = memory.id;
    if (memoryId == null || memoryId.isEmpty) {
      state = state.copyWith(errorMessage: AppStrings.memoryDeleteError);
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);

    try {
      await _repository.delete(memoryId);
      state = state.copyWith(isSubmitting: false);
      return true;
    } on Object catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _resolveErrorMessage(error),
      );
      return false;
    }
  }

  String? _validateContent(String content) {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      return AppStrings.memoryRequired;
    }

    if (trimmedContent.length > AppFieldLimits.memoryContent) {
      return AppStrings.memoryMaxLengthError;
    }

    return null;
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
}
