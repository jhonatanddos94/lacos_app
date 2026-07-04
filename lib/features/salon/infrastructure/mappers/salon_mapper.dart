import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/salon/domain/entities/salon.dart';

/// Converte objetos Parse da classe `Salon` para o domínio do Laços.
class SalonMapper {
  const SalonMapper();

  Salon toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError('Não foi possível carregar o salão. Tente novamente.');
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;

    return Salon(
      id: id,
      name: object.get<String>('name') ?? '',
      responsibleName: object.get<String>('responsibleName') ?? '',
      phone: object.get<String>('phone'),
      address: object.get<String>('address'),
      city: object.get<String>('city'),
      state: object.get<String>('state'),
      isActive: object.get<bool>('isActive') ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
