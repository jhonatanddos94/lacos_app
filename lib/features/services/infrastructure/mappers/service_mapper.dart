import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/services/domain/entities/service.dart';

class ServiceMapper {
  const ServiceMapper();

  Service toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError('Não foi possível carregar o serviço. Tente novamente.');
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;

    return Service(
      id: id,
      name: object.get<String>('name') ?? '',
      category: object.get<String>('category'),
      durationMinutes: object.get<int>('durationMinutes'),
      price: _price(object),
      description: object.get<String>('description'),
      isActive: object.get<bool>('isActive') ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  double? _price(ParseObject object) {
    final value = object.get<num>('price');
    return value?.toDouble();
  }
}
