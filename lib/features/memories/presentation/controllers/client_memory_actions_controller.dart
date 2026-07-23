import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

class ClientMemoryActionsState {
  const ClientMemoryActionsState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  ClientMemoryActionsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ClientMemoryActionsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

class ClientMemoryActionsController
    extends StateNotifier<ClientMemoryActionsState> {
  ClientMemoryActionsController(this._repository)
    : super(const ClientMemoryActionsState());

  final ClientMemoryRepository _repository;

  Future<ClientMemory?> setPinned({
    required String memoryId,
    required bool isPinned,
  }) async {
    if (state.isLoading) return null;

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final memory = await _repository.setPinned(
        memoryId: memoryId,
        isPinned: isPinned,
      );
      state = const ClientMemoryActionsState();
      return memory;
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveErrorMessage(error),
      );
      return null;
    }
  }

  Future<ClientMemory?> archive(String memoryId) async {
    if (state.isLoading) return null;

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final memory = await _repository.archive(memoryId);
      state = const ClientMemoryActionsState();
      return memory;
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveErrorMessage(error),
      );
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
}
