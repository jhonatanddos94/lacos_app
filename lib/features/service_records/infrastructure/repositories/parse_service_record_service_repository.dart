import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record_service.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_service_repository.dart';
import 'package:lacos_app/features/service_records/infrastructure/errors/parse_service_record_service_error_mapper.dart';
import 'package:lacos_app/features/service_records/infrastructure/mappers/service_record_service_mapper.dart';

class ParseServiceRecordServiceRepository
    implements ServiceRecordServiceRepository {
  ParseServiceRecordServiceRepository(
    this._salonRepository, {
    ServiceRecordServiceMapper? mapper,
    ParseServiceRecordServiceErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const ServiceRecordServiceMapper(),
       _errorMapper = errorMapper ?? const ParseServiceRecordServiceErrorMapper();

  static const _serviceRecordServiceClassName = 'ServiceRecordService';
  static const _serviceRecordClassName = 'ServiceRecord';
  static const _salonClassName = 'Salon';

  final SalonRepository _salonRepository;
  final ServiceRecordServiceMapper _mapper;
  final ParseServiceRecordServiceErrorMapper _errorMapper;

  @override
  Future<List<ServiceRecordService>> findByServiceRecord(
    String serviceRecordId,
  ) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(
        ParseObject(_serviceRecordServiceClassName),
      )
        ..whereEqualTo('serviceRecord', _serviceRecordPointer(serviceRecordId))
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..orderByAscending('createdAt');

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
          fallback: AppStrings.serviceRecordServiceLoadError,
        ),
      );
    }
  }

  @override
  Future<List<ServiceRecordService>> createMany({
    required String serviceRecordId,
    required List<ServiceRecordService> services,
  }) async {
    if (services.isEmpty) {
      return const [];
    }

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
      final createdServices = <ServiceRecordService>[];

      for (final service in services) {
        final parseServiceRecordService = ParseObject(
          _serviceRecordServiceClassName,
        );

        _mapper.applyToParse(
          object: parseServiceRecordService,
          serviceRecordId: serviceRecordId,
          service: service,
          salonId: salon.id,
          owner: owner,
        );

        final response = await parseServiceRecordService.save();
        if (!response.success) {
          throw FormatException(
            _errorMapper.toMessage(response.error, forSave: true),
          );
        }

        createdServices.add(_mapper.toDomain(parseServiceRecordService));
      }

      return createdServices;
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForSaveThrowable(
          error,
          fallback: AppStrings.serviceRecordServiceSaveError,
        ),
      );
    }
  }

  ParseObject _serviceRecordPointer(String serviceRecordId) {
    return ParseObject(_serviceRecordClassName)..objectId = serviceRecordId;
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }
}
