import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';

class ClientMemoryMapper {
  const ClientMemoryMapper();

  ClientMemory toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError(
        'Não foi possível carregar a memória. Tente novamente.',
      );
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;

    return ClientMemory(
      id: id,
      clientId: _requiredPointerId(object, 'client'),
      salonId: _requiredPointerId(object, 'salon'),
      professionalId: _optionalPointerId(object, 'professional'),
      ownerId: _ownerId(object),
      content: object.get<String>('content') ?? '',
      type: ClientMemoryType.fromParse(object.get<String>('type')),
      priority: ClientMemoryPriority.fromParse(object.get('priority')),
      isPinned: object.get<bool>('isPinned') ?? false,
      lastMentionedAt: object.get<DateTime>('lastMentionedAt'),
      isArchived: object.get<bool>('isArchived') ?? false,
      isActive: object.get<bool>('isActive') ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  void applyDomainFields({
    required ParseObject object,
    required ClientMemory memory,
  }) {
    object
      ..set<String>('content', memory.content)
      ..set<String>('type', memory.type.parseValue)
      ..set<String>('priority', memory.priority.parseValue)
      ..set<bool>('isPinned', memory.isPinned)
      ..set<bool>('isArchived', memory.isArchived)
      ..set<bool>('isActive', memory.isActive);

    final lastMentionedAt = memory.lastMentionedAt;
    if (lastMentionedAt != null) {
      object.set<DateTime>('lastMentionedAt', lastMentionedAt);
    } else {
      object.unset('lastMentionedAt');
    }
  }

  String _requiredPointerId(ParseObject object, String key) {
    final pointer = object.get<ParseObject>(key);
    final pointerId = pointer?.objectId;
    if (pointerId == null || pointerId.isEmpty) {
      throw StateError(
        'Não foi possível carregar a memória. Tente novamente.',
      );
    }

    return pointerId;
  }

  String? _optionalPointerId(ParseObject object, String key) {
    final pointer = object.get<ParseObject>(key);
    final pointerId = pointer?.objectId;
    if (pointerId == null || pointerId.isEmpty) {
      return null;
    }

    return pointerId;
  }

  String _ownerId(ParseObject object) {
    final owner =
        object.get<ParseUser>('owner') ?? object.get<ParseObject>('owner');
    final ownerId = owner?.objectId;
    if (ownerId == null || ownerId.isEmpty) {
      throw StateError(
        'Não foi possível carregar a memória. Tente novamente.',
      );
    }

    return ownerId;
  }
}
