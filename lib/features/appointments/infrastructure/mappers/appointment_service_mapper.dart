import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';

class AppointmentServiceMapper {
  const AppointmentServiceMapper();

  AppointmentService toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError(
        'Não foi possível carregar os serviços do agendamento. Tente novamente.',
      );
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;
    final durationMinutes = object.get<int>('durationMinutesAtBooking');

    if (durationMinutes == null) {
      throw StateError(
        'Não foi possível carregar os serviços do agendamento. Tente novamente.',
      );
    }

    final displayOrder = object.get<int>('displayOrder') ?? 0;

    return AppointmentService(
      id: id,
      appointmentId: _requiredPointerId(object, 'appointment'),
      serviceId: _requiredPointerId(object, 'service'),
      salonId: _requiredPointerId(object, 'salon'),
      ownerId: _ownerId(object),
      priceAtBooking: _priceAtBooking(object),
      durationMinutesAtBooking: durationMinutes,
      displayOrder: displayOrder,
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
        'Não foi possível carregar os serviços do agendamento. Tente novamente.',
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
        'Não foi possível carregar os serviços do agendamento. Tente novamente.',
      );
    }

    return ownerId;
  }

  double? _priceAtBooking(ParseObject object) {
    final value = object.get<num>('priceAtBooking');
    return value?.toDouble();
  }
}
