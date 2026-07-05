import 'dart:io';

import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/domain/exceptions/client_photo_upload_exception.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';
import 'package:lacos_app/features/clients/infrastructure/mappers/client_mapper.dart';
import 'package:lacos_app/features/clients/infrastructure/mappers/parse_client_error_mapper.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class ParseClientRepository implements ClientRepository {
  ParseClientRepository(
    this._salonRepository, {
    ClientMapper? mapper,
    ParseClientErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const ClientMapper(),
       _errorMapper = errorMapper ?? const ParseClientErrorMapper();

  static const _clientClassName = 'Client';
  static const _salonClassName = 'Salon';

  final SalonRepository _salonRepository;
  final ClientMapper _mapper;
  final ParseClientErrorMapper _errorMapper;

  @override
  Future<Client> create({
    required String name,
    required String phone,
    DateTime? birthDate,
    String? instagram,
    String? photoPath,
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

      final client = ParseObject(_clientClassName)
        ..set<String>('name', name)
        ..set<String>('phone', phone)
        ..set<bool>('isActive', true)
        ..set<DateTime>('clientSince', DateTime.now())
        ..set<ParseObject>('salon', _salonPointer(salon.id));

      if (birthDate != null) {
        client.set<DateTime>('birthDate', birthDate);
      }

      if (instagram != null && instagram.isNotEmpty) {
        client.set<String>('instagram', instagram);
      }

      final owner = ParseUser.forQuery()..objectId = currentUser.objectId;
      client.set<ParseUser>('owner', owner);

      final uploadedPhoto = await _uploadClientPhoto(photoPath);
      if (uploadedPhoto != null) {
        client.set<ParseFileBase>('photo', uploadedPhoto);
      }

      final response = await client.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      return _mapper.toDomain(client);
    } on StateError {
      rethrow;
    } on ClientPhotoUploadException {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'Não foi possível salvar a cliente. Tente novamente.',
      );
    }
  }

  @override
  Future<Client> update(Client client, {String? photoPath}) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_clientClassName))
        ..whereEqualTo('objectId', client.id)
        ..whereEqualTo('salon', _salonPointer(salon.id));

      final fetchResponse = await query.query<ParseObject>();
      if (!fetchResponse.success) {
        throw FormatException(_errorMapper.toMessage(fetchResponse.error));
      }

      final results = fetchResponse.results;
      if (results == null || results.isEmpty) {
        throw FormatException(AppStrings.clientUpdateError);
      }

      final parseClient = results.first as ParseObject;

      parseClient
        ..set<String>('name', client.name)
        ..set<String>('phone', client.phone);

      final birthDate = client.birthDate;
      if (birthDate != null) {
        parseClient.set<DateTime>('birthDate', birthDate);
      } else {
        parseClient.unset('birthDate');
      }

      final instagram = client.instagram;
      if (instagram != null && instagram.isNotEmpty) {
        parseClient.set<String>('instagram', instagram);
      } else {
        parseClient.unset('instagram');
      }

      if (photoPath != null) {
        final uploadedPhoto = await _uploadClientPhoto(photoPath);
        if (uploadedPhoto != null) {
          parseClient.set<ParseFileBase>('photo', uploadedPhoto);
        }
      }

      final response = await parseClient.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      return _mapper.toDomain(parseClient);
    } on StateError {
      rethrow;
    } on ClientPhotoUploadException {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw FormatException(AppStrings.clientUpdateError);
    }
  }

  @override
  Future<void> delete(String clientId) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_clientClassName))
        ..whereEqualTo('objectId', clientId)
        ..whereEqualTo('salon', _salonPointer(salon.id));

      final fetchResponse = await query.query<ParseObject>();
      if (!fetchResponse.success) {
        throw FormatException(_errorMapper.toMessage(fetchResponse.error));
      }

      final results = fetchResponse.results;
      if (results == null || results.isEmpty) {
        throw FormatException(AppStrings.clientDeleteError);
      }

      final parseClient = results.first as ParseObject;
      parseClient.set<bool>('isActive', false);

      final response = await parseClient.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw FormatException(AppStrings.clientDeleteError);
    }
  }

  @override
  Future<List<Client>> findAll() async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_clientClassName))
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
    } on Object {
      throw const FormatException(
        'Não foi possível carregar as clientes. Tente novamente.',
      );
    }
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }

  Future<ParseFile?> _uploadClientPhoto(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) {
      return null;
    }

    final file = File(photoPath);
    if (!await file.exists()) {
      throw const ClientPhotoUploadException();
    }

    final parseFile = ParseFile(file);
    final response = await parseFile.save();
    if (!response.success) {
      throw const ClientPhotoUploadException();
    }

    return parseFile;
  }
}
