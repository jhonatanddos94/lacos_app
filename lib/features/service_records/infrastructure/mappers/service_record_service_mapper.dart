import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';

class ServiceRecordServiceMapper {
  const ServiceRecordServiceMapper();

  static const _legacyPriceField = 'price';
  static const _finalAmountField = 'finalAmount';

  ServiceRecordService toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError(
        'Não foi possível carregar os serviços do atendimento. Tente novamente.',
      );
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;

    return ServiceRecordService(
      id: id,
      serviceRecordId: _requiredPointerId(object, 'serviceRecord'),
      serviceId: _requiredPointerId(object, 'service'),
      salonId: _requiredPointerId(object, 'salon'),
      ownerId: _ownerId(object),
      finalAmount: _finalAmount(object),
      notes: _notes(object),
      isActive: object.get<bool>('isActive') ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  void applyToParse({
    required ParseObject object,
    required String serviceRecordId,
    required ServiceRecordService service,
    required String salonId,
    required ParseUser owner,
  }) {
    object
      ..set<ParseObject>('serviceRecord', _serviceRecordPointer(serviceRecordId))
      ..set<ParseObject>('service', _servicePointer(service.serviceId))
      ..set<ParseObject>('salon', _salonPointer(salonId))
      ..set<ParseUser>('owner', owner)
      ..set<bool>('isActive', service.isActive);

    final finalAmount = service.finalAmount;
    if (finalAmount != null) {
      object.set<num>(_finalAmountField, finalAmount);
    } else {
      object.unset(_finalAmountField);
    }

    final notes = service.notes?.trim();
    if (notes == null || notes.isEmpty) {
      object.unset('notes');
    } else {
      object.set<String>('notes', notes);
    }
  }

  double? _finalAmount(ParseObject object) {
    final value = object.get<num>(_finalAmountField);
    if (value != null) {
      return value.toDouble();
    }

    final legacyValue = object.get<num>(_legacyPriceField);
    return legacyValue?.toDouble();
  }

  String? _notes(ParseObject object) {
    final value = object.get<String>('notes')?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String _requiredPointerId(ParseObject object, String key) {
    final pointer = object.get<ParseObject>(key);
    final pointerId = pointer?.objectId;
    if (pointerId == null || pointerId.isEmpty) {
      throw StateError(
        'Não foi possível carregar os serviços do atendimento. Tente novamente.',
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
        'Não foi possível carregar os serviços do atendimento. Tente novamente.',
      );
    }

    return ownerId;
  }

  ParseObject _serviceRecordPointer(String serviceRecordId) {
    return ParseObject(_serviceRecordClassName)..objectId = serviceRecordId;
  }

  ParseObject _servicePointer(String serviceId) {
    return ParseObject(_serviceClassName)..objectId = serviceId;
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }

  static const _serviceRecordClassName = 'ServiceRecord';
  static const _serviceClassName = 'Service';
  static const _salonClassName = 'Salon';
}
