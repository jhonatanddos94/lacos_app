import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/infrastructure/errors/parse_client_memory_error_mapper.dart';
import 'package:lacos_app/features/memories/infrastructure/mappers/client_memory_mapper.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class ParseClientMemoryRepository implements ClientMemoryRepository {
  ParseClientMemoryRepository(
    this._salonRepository,
    this._professionalRepository, {
    ClientMemoryMapper? mapper,
    ParseClientMemoryErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const ClientMemoryMapper(),
       _errorMapper = errorMapper ?? const ParseClientMemoryErrorMapper();

  static const _memoryClassName = 'ClientMemory';
  static const _clientClassName = 'Client';
  static const _salonClassName = 'Salon';
  static const _professionalClassName = 'Professional';

  final SalonRepository _salonRepository;
  final ProfessionalRepository _professionalRepository;
  final ClientMemoryMapper _mapper;
  final ParseClientMemoryErrorMapper _errorMapper;

  @override
  Future<ClientMemory> create(ClientMemory memory) async {
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

      final parseMemory = ParseObject(_memoryClassName)
        ..set<ParseObject>('client', _clientPointer(memory.clientId))
        ..set<ParseObject>('salon', _salonPointer(salon.id))
        ..set<ParseUser>(
          'owner',
          ParseUser.forQuery()..objectId = currentUser.objectId,
        );

      _mapper.applyDomainFields(object: parseMemory, memory: memory);

      final professional = await _professionalRepository.getCurrentProfessional();
      if (professional != null) {
        parseMemory.set<ParseObject>(
          'professional',
          _professionalPointer(professional.id),
        );
      }

      final response = await parseMemory.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      return _mapper.toDomain(parseMemory);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw FormatException(AppStrings.memorySaveError);
    }
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) async {
    try {
      final memoryId = memory.id;
      if (memoryId == null || memoryId.isEmpty) {
        throw FormatException(AppStrings.memoryUpdateError);
      }

      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_memoryClassName))
        ..whereEqualTo('objectId', memoryId)
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true);

      final fetchResponse = await query.query<ParseObject>();
      if (!fetchResponse.success) {
        throw FormatException(_errorMapper.toMessage(fetchResponse.error));
      }

      final results = fetchResponse.results;
      if (results == null || results.isEmpty) {
        throw FormatException(AppStrings.memoryUpdateError);
      }

      final parseMemory = results.first as ParseObject;
      _mapper.applyDomainFields(object: parseMemory, memory: memory);

      final response = await parseMemory.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      return _mapper.toDomain(parseMemory);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw FormatException(AppStrings.memoryUpdateError);
    }
  }

  @override
  Future<void> delete(String memoryId) async {
    try {
      if (memoryId.isEmpty) {
        throw FormatException(AppStrings.memoryDeleteError);
      }

      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_memoryClassName))
        ..whereEqualTo('objectId', memoryId)
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true);

      final fetchResponse = await query.query<ParseObject>();
      if (!fetchResponse.success) {
        throw FormatException(_errorMapper.toMessage(fetchResponse.error));
      }

      final results = fetchResponse.results;
      if (results == null || results.isEmpty) {
        throw FormatException(AppStrings.memoryDeleteError);
      }

      final parseMemory = results.first as ParseObject;
      parseMemory.set<bool>('isActive', false);

      final response = await parseMemory.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw FormatException(AppStrings.memoryDeleteError);
    }
  }

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
  }) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_memoryClassName))
        ..whereEqualTo('client', _clientPointer(clientId))
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..whereNotEqualTo('isArchived', true)
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
    } on Object {
      throw const FormatException(
        'Não foi possível carregar as memórias. Tente novamente.',
      );
    }
  }

  ParseObject _clientPointer(String clientId) {
    return ParseObject(_clientClassName)..objectId = clientId;
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }

  ParseObject _professionalPointer(String professionalId) {
    return ParseObject(_professionalClassName)..objectId = professionalId;
  }

  Future<ParseObject> _findActiveMemory(String memoryId) async {
    if (memoryId.isEmpty) {
      throw FormatException(AppStrings.memoryUpdateError);
    }

    final salon = await _salonRepository.getCurrentSalon();
    if (salon == null) {
      throw StateError(
        'Não encontramos seu salão. Cadastre um salão antes de continuar.',
      );
    }

    final query = QueryBuilder<ParseObject>(ParseObject(_memoryClassName))
      ..whereEqualTo('objectId', memoryId)
      ..whereEqualTo('salon', _salonPointer(salon.id))
      ..whereEqualTo('isActive', true)
      ..whereNotEqualTo('isArchived', true);

    final fetchResponse = await query.query<ParseObject>();
    if (!fetchResponse.success) {
      throw FormatException(_errorMapper.toMessage(fetchResponse.error));
    }

    final results = fetchResponse.results;
    if (results == null || results.isEmpty) {
      throw FormatException(AppStrings.memoryUpdateError);
    }

    return results.first as ParseObject;
  }

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) async {
    try {
      final parseMemory = await _findActiveMemory(memoryId);
      parseMemory.set<bool>('isPinned', isPinned);

      final response = await parseMemory.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      return _mapper.toDomain(parseMemory);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw FormatException(AppStrings.memoryPinError);
    }
  }

  @override
  Future<ClientMemory> archive(String memoryId) async {
    try {
      final parseMemory = await _findActiveMemory(memoryId);
      parseMemory.set<bool>('isArchived', true);

      final response = await parseMemory.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      return _mapper.toDomain(parseMemory);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw FormatException(AppStrings.memoryArchiveError);
    }
  }

  @override
  Future<void> touchMentioned({
    required List<String> memoryIds,
  }) async {
    final normalizedIds = memoryIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedIds.isEmpty) {
      return;
    }

    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        return;
      }

      final query = QueryBuilder<ParseObject>(ParseObject(_memoryClassName))
        ..whereContainedIn('objectId', normalizedIds)
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..whereNotEqualTo('isArchived', true);

      final fetchResponse = await query.query<ParseObject>();
      if (!fetchResponse.success) {
        return;
      }

      final results = fetchResponse.results;
      if (results == null || results.isEmpty) {
        return;
      }

      final now = DateTime.now();
      final saveFutures = results.whereType<ParseObject>().map((parseMemory) {
        parseMemory.set<DateTime>('lastMentionedAt', now);
        return parseMemory.save();
      }).toList(growable: false);

      if (saveFutures.isEmpty) {
        return;
      }

      await Future.wait(saveFutures);
    } on Object {
      return;
    }
  }
}
