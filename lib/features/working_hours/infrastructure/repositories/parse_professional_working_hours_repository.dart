import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';
import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';
import 'package:lacos_app/features/working_hours/domain/repositories/professional_working_hours_repository.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_hours_validator.dart';
import 'package:lacos_app/features/working_hours/infrastructure/mappers/parse_professional_working_hours_error_mapper.dart';
import 'package:lacos_app/features/working_hours/infrastructure/mappers/professional_working_hours_mapper.dart';

/// Parse class: `ProfessionalWorkingHours`
///
/// Schema manual no Back4App (não usar Add Field em runtime):
/// - salon: Pointer to Salon (required)
/// - professional: Pointer to Professional (required)
/// - weekday: Number 1..7 (required)
/// - isWorking: Boolean (required)
/// - startMinutes: Number (required)
/// - endMinutes: Number (required)
///
/// Índice/composto recomendado: unique (salon, professional, weekday).
/// Segurança adicional depende de CLP/ACL server-side.
class ParseProfessionalWorkingHoursRepository
    implements ProfessionalWorkingHoursRepository {
  ParseProfessionalWorkingHoursRepository(
    this._salonRepository,
    this._professionalRepository, {
    ProfessionalWorkingHoursMapper? mapper,
    ParseProfessionalWorkingHoursErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const ProfessionalWorkingHoursMapper(),
       _errorMapper =
           errorMapper ?? const ParseProfessionalWorkingHoursErrorMapper();

  static const _className = 'ProfessionalWorkingHours';
  static const _salonClassName = 'Salon';
  static const _professionalClassName = 'Professional';

  final SalonRepository _salonRepository;
  final ProfessionalRepository _professionalRepository;
  final ProfessionalWorkingHoursMapper _mapper;
  final ParseProfessionalWorkingHoursErrorMapper _errorMapper;

  @override
  Future<List<ProfessionalWorkingHours>> findWeek({
    required String salonId,
    required String professionalId,
  }) async {
    try {
      await _assertScopedAccess(
        expectedSalonId: salonId,
        expectedProfessionalId: professionalId,
      );

      final query = QueryBuilder<ParseObject>(ParseObject(_className))
        ..whereEqualTo('salon', _salonPointer(salonId))
        ..whereEqualTo('professional', _professionalPointer(professionalId))
        ..orderByAscending('weekday');

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
          fallback: AppStrings.workingHoursLoadError,
        ),
      );
    }
  }

  /// Save coordenado da semana: upsert dos 7 dias via writes Parse paralelos.
  /// Persistência parcial é possível se algum write falhar no meio.
  @override
  Future<List<ProfessionalWorkingHours>> saveWeek({
    required String salonId,
    required String professionalId,
    required List<ProfessionalWorkingHours> week,
  }) async {
    try {
      await _assertScopedAccess(
        expectedSalonId: salonId,
        expectedProfessionalId: professionalId,
      );

      final validationError = WorkingHoursValidator.validateWeek(week);
      if (validationError != null) {
        throw FormatException(validationError);
      }

      final existing = await findWeek(
        salonId: salonId,
        professionalId: professionalId,
      );
      final existingByWeekday = {
        for (final entry in existing) entry.weekday: entry,
      };

      final saveFutures = week.map((day) {
        final existingEntry = existingByWeekday[day.weekday];
        final parseObject = existingEntry == null
            ? ParseObject(_className)
            : (ParseObject(_className)..objectId = existingEntry.id);

        parseObject
          ..set<ParseObject>('salon', _salonPointer(salonId))
          ..set<ParseObject>('professional', _professionalPointer(professionalId))
          ..set<int>('weekday', day.weekday)
          ..set<bool>('isWorking', day.isWorking)
          ..set<int>('startMinutes', day.startMinutes)
          ..set<int>('endMinutes', day.endMinutes);

        return parseObject.save();
      }).toList(growable: false);

      final responses = await Future.wait(saveFutures);
      for (final response in responses) {
        if (!response.success) {
          throw FormatException(
            _errorMapper.toMessage(response.error, forSave: true),
          );
        }
      }

      return findWeek(salonId: salonId, professionalId: professionalId);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: AppStrings.workingHoursSaveError,
        ),
      );
    }
  }

  Future<void> _assertScopedAccess({
    required String expectedSalonId,
    required String expectedProfessionalId,
  }) async {
    final salon = await _salonRepository.getCurrentSalon();
    if (salon == null || salon.id != expectedSalonId) {
      throw StateError(
        'Não encontramos seu salão. Cadastre um salão antes de continuar.',
      );
    }

    final professional = await _professionalRepository.getCurrentProfessional();
    if (professional == null || professional.id != expectedProfessionalId) {
      throw StateError(AppStrings.workingHoursProfessionalRequired);
    }
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }

  ParseObject _professionalPointer(String professionalId) {
    return ParseObject(_professionalClassName)..objectId = professionalId;
  }
}
