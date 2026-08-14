import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';
import 'package:lacos_app/features/salon/infrastructure/mappers/parse_salon_error_mapper.dart';
import 'package:lacos_app/features/salon/infrastructure/mappers/salon_mapper.dart';

/// Implementação de [SalonRepository] com Back4App/Parse.
class ParseSalonRepository implements SalonRepository {
  ParseSalonRepository({
    SalonMapper? mapper,
    ParseSalonErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const SalonMapper(),
       _errorMapper = errorMapper ?? const ParseSalonErrorMapper();

  static const _salonClassName = 'Salon';

  final SalonMapper _mapper;
  final ParseSalonErrorMapper _errorMapper;

  @override
  Future<Salon?> getCurrentSalon() async {
    try {
      final currentUser = await ParseUser.currentUser();
      if (currentUser is! ParseUser || currentUser.objectId == null) {
        throw StateError(
          'Não encontramos uma sessão ativa no servidor. Entre novamente.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_salonClassName))
        ..whereEqualTo('owner', currentUser)
        ..setLimit(1);

      final response = await query.query<ParseObject>();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      final results = response.results;
      if (results == null || results.isEmpty) {
        return null;
      }

      // TODO: permitir seleção de salão para contas multi-salão.
      return _mapper.toDomain(results.first as ParseObject);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: 'Não foi possível carregar seu salão. Tente novamente.',
        ),
      );
    }
  }

  @override
  Future<Salon> create({
    required String name,
    required String responsibleName,
  }) async {
    try {
      // TODO: sincronizar sessão Firebase -> Parse quando a integração estiver pronta.
      final currentUser = await ParseUser.currentUser();
      if (currentUser is! ParseUser || currentUser.objectId == null) {
        throw StateError(
          'Não encontramos uma sessão ativa no servidor. Entre novamente.',
        );
      }

      final salon = ParseObject(_salonClassName)
        ..set<String>('name', name)
        ..set<String>('responsibleName', responsibleName)
        ..set<bool>('isActive', true);

      final owner = ParseUser.forQuery()..objectId = currentUser.objectId;
      salon.set<ParseUser>('owner', owner);

      final response = await salon.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      return _mapper.toDomain(salon);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'Não foi possível criar seu salão. Tente novamente.',
      );
    }
  }

  @override
  Future<Salon> update({
    required String salonId,
    required String name,
    String? phone,
    String? address,
    String? city,
    String? state,
  }) async {
    try {
      final currentUser = await ParseUser.currentUser();
      if (currentUser is! ParseUser || currentUser.objectId == null) {
        throw StateError(
          'Não encontramos uma sessão ativa no servidor. Entre novamente.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_salonClassName))
        ..whereEqualTo('objectId', salonId)
        ..whereEqualTo('owner', currentUser)
        ..setLimit(1);
      final fetchResponse = await query.query<ParseObject>();
      if (!fetchResponse.success) {
        throw FormatException(_updateErrorMessage(fetchResponse.error));
      }

      final results = fetchResponse.results;
      if (results == null || results.isEmpty) {
        throw const FormatException(AppStrings.salonUpdateError);
      }

      final salon = results.first as ParseObject..set<String>('name', name);
      _setOptionalString(salon, 'phone', phone);
      _setOptionalString(salon, 'address', address);
      _setOptionalString(salon, 'city', city);
      _setOptionalString(salon, 'state', state);

      final response = await salon.save();
      if (!response.success) {
        throw FormatException(_updateErrorMessage(response.error));
      }
      return _mapper.toDomain(salon);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(AppStrings.salonUpdateError);
    }
  }

  String _updateErrorMessage(ParseError? error) {
    if (ParseTemporaryErrorMapper.isTemporaryParseError(error)) {
      return AppStrings.temporarySaveError;
    }
    if (error?.code == ParseError.invalidSessionToken) {
      return 'Sua sessão expirou. Entre novamente.';
    }
    return AppStrings.salonUpdateError;
  }

  void _setOptionalString(ParseObject object, String key, String? value) {
    if (value != null && value.isNotEmpty) {
      object.set<String>(key, value);
    } else {
      object.unset(key);
    }
  }
}
