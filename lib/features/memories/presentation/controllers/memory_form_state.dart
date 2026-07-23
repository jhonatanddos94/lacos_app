import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';

class MemoryFormState {
  const MemoryFormState({
    this.content = '',
    this.type = ClientMemoryType.other,
    this.priority = ClientMemoryPriority.normal,
    this.isPinned = false,
    this.isEditing = false,
    this.isSubmitting = false,
    this.contentError,
    this.errorMessage,
  });

  final String content;
  final ClientMemoryType type;
  final ClientMemoryPriority priority;
  final bool isPinned;
  final bool isEditing;
  final bool isSubmitting;
  final String? contentError;
  final String? errorMessage;

  MemoryFormState copyWith({
    String? content,
    ClientMemoryType? type,
    ClientMemoryPriority? priority,
    bool? isPinned,
    bool? isEditing,
    bool? isSubmitting,
    String? contentError,
    bool clearContentError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return MemoryFormState(
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      isEditing: isEditing ?? this.isEditing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      contentError:
          clearContentError ? null : (contentError ?? this.contentError),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
