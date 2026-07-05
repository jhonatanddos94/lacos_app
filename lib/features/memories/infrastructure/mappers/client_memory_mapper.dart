import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

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
      isActive: object.get<bool>('isActive') ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
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
    final owner = object.get<ParseUser>('owner') ?? object.get<ParseObject>('owner');
    final ownerId = owner?.objectId;
    if (ownerId == null || ownerId.isEmpty) {
      throw StateError(
        'Não foi possível carregar a memória. Tente novamente.',
      );
    }

    return ownerId;
  }
}
