import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/domain/repositories/service_repository.dart';
import 'package:lacos_app/features/services/infrastructure/mappers/parse_service_error_mapper.dart';
import 'package:lacos_app/features/services/infrastructure/mappers/service_mapper.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class ParseServiceRepository implements ServiceRepository {
  ParseServiceRepository(
    this._salonRepository, {
    ServiceMapper? mapper,
    ParseServiceErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const ServiceMapper(),
       _errorMapper = errorMapper ?? const ParseServiceErrorMapper();

  static const _serviceClassName = 'Service';
  static const _salonClassName = 'Salon';

  final SalonRepository _salonRepository;
  final ServiceMapper _mapper;
  final ParseServiceErrorMapper _errorMapper;

  @override
  Future<List<Service>> findAll() async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_serviceClassName))
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..orderByAscending('name');

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
          fallback: AppStrings.servicesLoadError,
        ),
      );
    }
  }

  @override
  Future<Service> create({
    required String name,
    required int durationMinutes,
    String? category,
    double? price,
    String? description,
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

      final service = ParseObject(_serviceClassName)
        ..set<String>('name', name)
        ..set<bool>('isActive', true)
        ..set<int>('durationMinutes', durationMinutes)
        ..set<ParseObject>('salon', _salonPointer(salon.id));

      if (category != null && category.isNotEmpty) {
        service.set<String>('category', category);
      }

      if (price != null) {
        service.set<num>('price', price);
      }

      if (description != null && description.isNotEmpty) {
        service.set<String>('description', description);
      }

      final owner = ParseUser.forQuery()..objectId = currentUser.objectId;
      service.set<ParseUser>('owner', owner);

      final response = await service.save();
      if (!response.success) {
        throw FormatException(
          _errorMapper.toMessage(response.error, forSave: true),
        );
      }

      return _mapper.toDomain(service);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: AppStrings.serviceSaveError,
        ),
      );
    }
  }

  @override
  Future<Service> update(Service service) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_serviceClassName))
        ..whereEqualTo('objectId', service.id)
        ..whereEqualTo('salon', _salonPointer(salon.id));

      final fetchResponse = await query.query<ParseObject>();
      if (!fetchResponse.success) {
        throw FormatException(_errorMapper.toMessage(fetchResponse.error));
      }

      final results = fetchResponse.results;
      if (results == null || results.isEmpty) {
        throw FormatException(AppStrings.serviceUpdateError);
      }

      final parseService = results.first as ParseObject;

      parseService
        ..set<String>('name', service.name)
        ..set<int>('durationMinutes', service.durationMinutes ?? 0);

      final category = service.category;
      if (category != null && category.isNotEmpty) {
        parseService.set<String>('category', category);
      } else {
        parseService.unset('category');
      }

      final price = service.price;
      if (price != null) {
        parseService.set<num>('price', price);
      } else {
        parseService.unset('price');
      }

      final description = service.description;
      if (description != null && description.isNotEmpty) {
        parseService.set<String>('description', description);
      } else {
        parseService.unset('description');
      }

      final response = await parseService.save();
      if (!response.success) {
        throw FormatException(
          _errorMapper.toMessage(response.error, forSave: true),
        );
      }

      return _mapper.toDomain(parseService);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: AppStrings.serviceUpdateError,
        ),
      );
    }
  }

  @override
  Future<void> delete(String serviceId) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_serviceClassName))
        ..whereEqualTo('objectId', serviceId)
        ..whereEqualTo('salon', _salonPointer(salon.id));

      final fetchResponse = await query.query<ParseObject>();
      if (!fetchResponse.success) {
        throw FormatException(_errorMapper.toMessage(fetchResponse.error));
      }

      final results = fetchResponse.results;
      if (results == null || results.isEmpty) {
        throw FormatException(AppStrings.serviceDeleteError);
      }

      final parseService = results.first as ParseObject;
      parseService.set<bool>('isActive', false);

      final response = await parseService.save();
      if (!response.success) {
        throw FormatException(
          _errorMapper.toMessage(response.error, forSave: true),
        );
      }
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: AppStrings.serviceDeleteError,
        ),
      );
    }
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }
}
