import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';

class ServiceRecordMapper {
  const ServiceRecordMapper();

  static const _procedureSummaryField = 'procedureSummary';
  static const _legacyPerformedProcedureField = 'performedProcedure';
  static const _finalAmountField = 'finalAmount';
  static const _legacyChargedAmountField = 'chargedAmount';
  static const _legacyServiceField = 'service';

  ServiceRecord toDomain(ParseObject object) {
    final id = object.objectId;
    if (id == null || id.isEmpty) {
      throw StateError(
        'Não foi possível carregar o histórico do atendimento. Tente novamente.',
      );
    }

    final createdAt = object.createdAt ?? DateTime.now();
    final updatedAt = object.updatedAt ?? createdAt;

    return ServiceRecord(
      id: id,
      appointmentId: _optionalPointerId(object, 'appointment'),
      clientId: _requiredPointerId(object, 'client'),
      professionalId: _requiredPointerId(object, 'professional'),
      salonId: _requiredPointerId(object, 'salon'),
      ownerId: _ownerId(object),
      serviceDate: _serviceDate(object),
      procedureSummary: _procedureSummary(object),
      technicalNotes: _optionalTrimmedString(object, 'technicalNotes'),
      result: _optionalTrimmedString(object, 'result'),
      finalAmount: _finalAmount(object),
      productsUsed: _optionalTrimmedString(object, 'productsUsed'),
      isActive: object.get<bool>('isActive') ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  void applyToParse({
    required ParseObject object,
    required ServiceRecord record,
    required String salonId,
    required ParseUser owner,
    String? legacyPrimaryServiceId,
  }) {
    final appointmentId = record.appointmentId?.trim();
    if (appointmentId != null && appointmentId.isNotEmpty) {
      object.set<ParseObject>(
        'appointment',
        _appointmentPointer(appointmentId),
      );
    } else {
      object.unset('appointment');
    }

    object
      ..set<ParseObject>('client', _clientPointer(record.clientId))
      ..set<ParseObject>(
        'professional',
        _professionalPointer(record.professionalId),
      )
      ..set<ParseObject>('salon', _salonPointer(salonId))
      ..set<ParseUser>('owner', owner)
      ..set<bool>('isActive', record.isActive);

    final serviceDate = record.serviceDate;
    if (serviceDate != null) {
      object.set<DateTime>('serviceDate', serviceDate);
    } else {
      object.unset('serviceDate');
    }

    _setOptionalString(object, _procedureSummaryField, record.procedureSummary);
    _setOptionalString(object, 'technicalNotes', record.technicalNotes);
    _setOptionalString(object, 'result', record.result);
    _setOptionalString(object, 'productsUsed', record.productsUsed);

    final finalAmount = record.finalAmount;
    if (finalAmount != null) {
      object.set<num>(_finalAmountField, finalAmount);
    } else {
      object.unset(_finalAmountField);
    }

    final primaryServiceId = legacyPrimaryServiceId?.trim();
    if (primaryServiceId != null && primaryServiceId.isNotEmpty) {
      object.set<ParseObject>(
        _legacyServiceField,
        _servicePointer(primaryServiceId),
      );
    }
  }

  String? _procedureSummary(ParseObject object) {
    final value = _optionalTrimmedString(object, _procedureSummaryField);
    if (value != null) {
      return value;
    }

    return _optionalTrimmedString(object, _legacyPerformedProcedureField);
  }

  double? _finalAmount(ParseObject object) {
    final value = object.get<num>(_finalAmountField);
    if (value != null) {
      return value.toDouble();
    }

    final legacyValue = object.get<num>(_legacyChargedAmountField);
    return legacyValue?.toDouble();
  }

  DateTime? _serviceDate(ParseObject object) {
    final value = object.get<DateTime>('serviceDate');
    return value?.toLocal();
  }

  String? _optionalTrimmedString(ParseObject object, String key) {
    final value = object.get<String>(key)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  void _setOptionalString(ParseObject object, String key, String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      object.unset(key);
      return;
    }

    object.set<String>(key, trimmed);
  }

  String _requiredPointerId(ParseObject object, String key) {
    final pointer = object.get<ParseObject>(key);
    final pointerId = pointer?.objectId;
    if (pointerId == null || pointerId.isEmpty) {
      throw StateError(
        'Não foi possível carregar o histórico do atendimento. Tente novamente.',
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
        'Não foi possível carregar o histórico do atendimento. Tente novamente.',
      );
    }

    return ownerId;
  }

  ParseObject _appointmentPointer(String appointmentId) {
    return ParseObject(_appointmentClassName)..objectId = appointmentId;
  }

  ParseObject _clientPointer(String clientId) {
    return ParseObject(_clientClassName)..objectId = clientId;
  }

  ParseObject _professionalPointer(String professionalId) {
    return ParseObject(_professionalClassName)..objectId = professionalId;
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }

  ParseObject _servicePointer(String serviceId) {
    return ParseObject(_serviceClassName)..objectId = serviceId;
  }

  static const _appointmentClassName = 'Appointment';
  static const _clientClassName = 'Client';
  static const _professionalClassName = 'Professional';
  static const _salonClassName = 'Salon';
  static const _serviceClassName = 'Service';
}
