import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/professional/domain/entities/professional.dart';

class ProfessionalMapper {
  const ProfessionalMapper();

  Professional toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError(
        'Não foi possível carregar seu perfil profissional. Tente novamente.',
      );
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;

    return Professional(
      id: id,
      name: object.get<String>('name') ?? '',
      role: object.get<String>('role'),
      specialties: object.get<String>('specialties'),
      isActive: object.get<bool>('isActive') ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
