import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';

class AppointmentMapper {
  const AppointmentMapper();

  Appointment toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError(
        'Não foi possível carregar o agendamento. Tente novamente.',
      );
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;
    final startAt = object.get<DateTime>('startAt');
    final endAt = object.get<DateTime>('endAt');

    if (startAt == null || endAt == null) {
      throw StateError(
        'Não foi possível carregar o agendamento. Tente novamente.',
      );
    }

    final statusValue = object.get<String>('status') ?? 'pending';

    return Appointment(
      id: id,
      salonId: _requiredPointerId(object, 'salon'),
      ownerId: _ownerId(object),
      clientId: _requiredPointerId(object, 'client'),
      professionalId: _requiredPointerId(object, 'professional'),
      startAt: startAt.toLocal(),
      endAt: endAt.toLocal(),
      status: AppointmentStatus.fromParse(statusValue),
      notes: object.get<String>('notes'),
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
        'Não foi possível carregar o agendamento. Tente novamente.',
      );
    }

    return pointerId;
  }

  String _ownerId(ParseObject object) {
    final owner =
        object.get<ParseUser>('owner') ?? object.get<ParseObject>('owner');
    final ownerId = owner?.objectId;
    if (ownerId == null || ownerId.isEmpty) {
      throw StateError(
        'Não foi possível carregar o agendamento. Tente novamente.',
      );
    }

    return ownerId;
  }
}
