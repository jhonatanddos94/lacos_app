import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/service_records/infrastructure/errors/parse_service_record_error_mapper.dart';
import 'package:lacos_app/features/service_records/infrastructure/mappers/service_record_mapper.dart';

class ParseServiceRecordRepository implements ServiceRecordRepository {
  ParseServiceRecordRepository(
    this._salonRepository, {
    ServiceRecordMapper? mapper,
    ParseServiceRecordErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const ServiceRecordMapper(),
       _errorMapper = errorMapper ?? const ParseServiceRecordErrorMapper();

  static const _serviceRecordClassName = 'ServiceRecord';
  static const _appointmentClassName = 'Appointment';
  static const _clientClassName = 'Client';
  static const _salonClassName = 'Salon';

  final SalonRepository _salonRepository;
  final ServiceRecordMapper _mapper;
  final ParseServiceRecordErrorMapper _errorMapper;

  @override
  Future<ServiceRecord> create(
    ServiceRecord record, {
    String? legacyPrimaryServiceId,
  }) async {
    try {
      final currentUser = await ParseUser.currentUser();
      if (currentUser is! ParseUser || currentUser.objectId == null) {
        throw StateError(
          'Não encontramos uma sessão ativa no servidor. Entre novamente.',
        );
      }

      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final owner = ParseUser.forQuery()..objectId = currentUser.objectId;
      final parseServiceRecord = ParseObject(_serviceRecordClassName);

      _mapper.applyToParse(
        object: parseServiceRecord,
        record: record,
        salonId: salon.id,
        owner: owner,
        legacyPrimaryServiceId: legacyPrimaryServiceId,
      );

      final response = await parseServiceRecord.save();
      if (!response.success) {
        throw FormatException(
          _errorMapper.toMessage(response.error, forSave: true),
        );
      }

      return _mapper.toDomain(parseServiceRecord);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForSaveThrowable(
          error,
          fallback: AppStrings.serviceRecordSaveError,
        ),
      );
    }
  }

  @override
  Future<ServiceRecord?> findByAppointmentId(String appointmentId) async {
    if (appointmentId.isEmpty) {
      return null;
    }

    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(
        ParseObject(_serviceRecordClassName),
      )
        ..whereEqualTo('appointment', _appointmentPointer(appointmentId))
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..orderByDescending('createdAt');

      final response = await query.query<ParseObject>();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      final results = response.results;
      if (results == null || results.isEmpty) {
        return null;
      }

      return _mapper.toDomain(results.first as ParseObject);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: AppStrings.serviceRecordLoadError,
        ),
      );
    }
  }

  @override
  Future<List<ServiceRecord>> findByClientId(String clientId) async {
    if (clientId.isEmpty) {
      return const [];
    }

    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(
        ParseObject(_serviceRecordClassName),
      )
        ..whereEqualTo('client', _clientPointer(clientId))
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..orderByDescending('serviceDate')
        ..orderByDescending('createdAt');

      final response = await query.query<ParseObject>();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      final results = response.results;
      if (results == null || results.isEmpty) {
        return const [];
      }

      return results
          .whereType<ParseObject>()
          .map(_mapper.toDomain)
          .toList(growable: false);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: AppStrings.serviceRecordLoadError,
        ),
      );
    }
  }

  ParseObject _appointmentPointer(String appointmentId) {
    return ParseObject(_appointmentClassName)..objectId = appointmentId;
  }

  ParseObject _clientPointer(String clientId) {
    return ParseObject(_clientClassName)..objectId = clientId;
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }
}
