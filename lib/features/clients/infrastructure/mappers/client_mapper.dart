import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/infrastructure/parse/parse_photo_file_upload.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';

class ClientMapper {
  const ClientMapper();

  Client toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError('Não foi possível carregar a cliente. Tente novamente.');
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;

    return Client(
      id: id,
      name: object.get<String>('name') ?? '',
      phone: object.get<String>('phone') ?? '',
      birthDate: object.get<DateTime>('birthDate'),
      photoUrl: parsePhotoUrl(object),
      instagram: object.get<String>('instagram'),
      isActive: object.get<bool>('isActive') ?? true,
      isFavorite: object.get<bool>('isFavorite') ?? false,
      clientSince: object.get<DateTime>('clientSince'),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
