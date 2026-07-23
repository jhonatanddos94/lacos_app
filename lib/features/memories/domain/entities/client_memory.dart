import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';

class ClientMemory {
  const ClientMemory({
    this.id,
    required this.clientId,
    required this.salonId,
    this.professionalId,
    required this.ownerId,
    required this.content,
    this.type = ClientMemoryType.other,
    this.priority = ClientMemoryPriority.normal,
    this.isPinned = false,
    this.lastMentionedAt,
    this.isArchived = false,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String clientId;
  final String salonId;
  final String? professionalId;
  final String ownerId;
  final String content;
  final ClientMemoryType type;
  final ClientMemoryPriority priority;
  final bool isPinned;
  final DateTime? lastMentionedAt;
  final bool isArchived;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isVisible => isActive && !isArchived;

  factory ClientMemory.draft({
    required String clientId,
    required String content,
  }) {
    return ClientMemory(
      clientId: clientId,
      salonId: '',
      ownerId: '',
      content: content,
      isActive: true,
    );
  }

  ClientMemory copyWith({
    String? id,
    String? clientId,
    String? salonId,
    String? professionalId,
    String? ownerId,
    String? content,
    ClientMemoryType? type,
    ClientMemoryPriority? priority,
    bool? isPinned,
    DateTime? lastMentionedAt,
    bool clearLastMentionedAt = false,
    bool? isArchived,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientMemory(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      salonId: salonId ?? this.salonId,
      professionalId: professionalId ?? this.professionalId,
      ownerId: ownerId ?? this.ownerId,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      lastMentionedAt: clearLastMentionedAt
          ? null
          : (lastMentionedAt ?? this.lastMentionedAt),
      isArchived: isArchived ?? this.isArchived,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
