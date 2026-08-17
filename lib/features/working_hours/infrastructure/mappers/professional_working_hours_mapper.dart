import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';

class ProfessionalWorkingHoursMapper {
  const ProfessionalWorkingHoursMapper();

  ProfessionalWorkingHours toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError('Não foi possível carregar os horários. Tente novamente.');
    }

    final weekday = object.get<num>('weekday')?.toInt();
    final startMinutes = object.get<num>('startMinutes')?.toInt();
    final endMinutes = object.get<num>('endMinutes')?.toInt();
    if (weekday == null || startMinutes == null || endMinutes == null) {
      throw StateError('Não foi possível carregar os horários. Tente novamente.');
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;

    return ProfessionalWorkingHours(
      id: id,
      salonId: _requiredPointerId(object, 'salon'),
      professionalId: _requiredPointerId(object, 'professional'),
      weekday: weekday,
      isWorking: object.get<bool>('isWorking') ?? true,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String _requiredPointerId(ParseObject object, String key) {
    final pointer = object.get<ParseObject>(key);
    final pointerId = pointer?.objectId;
    if (pointerId == null || pointerId.isEmpty) {
      throw StateError('Não foi possível carregar os horários. Tente novamente.');
    }

    return pointerId;
  }
}
