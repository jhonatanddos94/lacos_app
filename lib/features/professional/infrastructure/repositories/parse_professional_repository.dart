import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/professional/infrastructure/mappers/parse_professional_error_mapper.dart';
import 'package:lacos_app/features/professional/infrastructure/mappers/professional_mapper.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class ParseProfessionalRepository implements ProfessionalRepository {
  ParseProfessionalRepository(
    this._salonRepository, {
    ProfessionalMapper? mapper,
    ParseProfessionalErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const ProfessionalMapper(),
       _errorMapper = errorMapper ?? const ParseProfessionalErrorMapper();

  static const _professionalClassName = 'Professional';
  static const _salonClassName = 'Salon';

  final SalonRepository _salonRepository;
  final ProfessionalMapper _mapper;
  final ParseProfessionalErrorMapper _errorMapper;

  @override
  Future<Professional> create({
    required String name,
    String? specialties,
  }) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final professional = ParseObject(_professionalClassName)
        ..set<String>('name', name)
        ..set<bool>('isActive', true);

      if (specialties != null && specialties.isNotEmpty) {
        professional.set<String>('specialties', specialties);
      }

      professional.set<ParseObject>('salon', _salonPointer(salon.id));

      final response = await professional.save();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      return _mapper.toDomain(professional);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'Não foi possível salvar seu perfil profissional. Tente novamente.',
      );
    }
  }

  @override
  Future<Professional?> getCurrentProfessional() async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        return null;
      }

      final query =
          QueryBuilder<ParseObject>(ParseObject(_professionalClassName))
            ..whereEqualTo('salon', _salonPointer(salon.id))
            ..whereEqualTo('isActive', true)
            ..setLimit(1);

      final response = await query.query<ParseObject>();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      final results = response.results;
      if (results == null || results.isEmpty) {
        return null;
      }

      // TODO: permitir seleção de profissional em contas com múltiplos profissionais.
      return _mapper.toDomain(results.first as ParseObject);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'Não foi possível carregar seu perfil profissional. Tente novamente.',
      );
    }
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }
}
