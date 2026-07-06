import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/infrastructure/errors/parse_appointment_error_mapper.dart';
import 'package:lacos_app/features/appointments/infrastructure/mappers/appointment_mapper.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class ParseAppointmentRepository implements AppointmentRepository {
  ParseAppointmentRepository(
    this._salonRepository, {
    AppointmentMapper? mapper,
    ParseAppointmentErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const AppointmentMapper(),
       _errorMapper = errorMapper ?? const ParseAppointmentErrorMapper();

  static const _appointmentClassName = 'Appointment';
  static const _salonClassName = 'Salon';

  final SalonRepository _salonRepository;
  final AppointmentMapper _mapper;
  final ParseAppointmentErrorMapper _errorMapper;

  @override
  Future<List<Appointment>> findByDay(DateTime day) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final query = QueryBuilder<ParseObject>(
        ParseObject(_appointmentClassName),
      )
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..whereGreaterThanOrEqualsTo('startAt', dayStart)
        ..whereLessThan('startAt', dayEnd)
        ..orderByAscending('startAt');

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
          fallback:
              'Não foi possível carregar os agendamentos. Tente novamente.',
        ),
      );
    }
  }

  @override
  Future<Appointment> create(Appointment appointment) {
    throw UnimplementedError('create() será implementado em etapa futura.');
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError('update() será implementado em etapa futura.');
  }

  @override
  Future<void> delete(String appointmentId) {
    throw UnimplementedError('delete() será implementado em etapa futura.');
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }
}
