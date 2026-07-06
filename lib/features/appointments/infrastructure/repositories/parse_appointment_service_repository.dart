import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/infrastructure/errors/parse_appointment_service_error_mapper.dart';
import 'package:lacos_app/features/appointments/infrastructure/mappers/appointment_service_mapper.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';

class ParseAppointmentServiceRepository implements AppointmentServiceRepository {
  ParseAppointmentServiceRepository(
    this._salonRepository, {
    AppointmentServiceMapper? mapper,
    ParseAppointmentServiceErrorMapper? errorMapper,
  }) : _mapper = mapper ?? const AppointmentServiceMapper(),
       _errorMapper = errorMapper ?? const ParseAppointmentServiceErrorMapper();

  static const _appointmentServiceClassName = 'AppointmentService';
  static const _appointmentClassName = 'Appointment';
  static const _salonClassName = 'Salon';

  final SalonRepository _salonRepository;
  final AppointmentServiceMapper _mapper;
  final ParseAppointmentServiceErrorMapper _errorMapper;

  @override
  Future<List<AppointmentService>> findByAppointment(
    String appointmentId,
  ) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final query = QueryBuilder<ParseObject>(
        ParseObject(_appointmentServiceClassName),
      )
        ..whereEqualTo('appointment', _appointmentPointer(appointmentId))
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..orderByAscending('displayOrder');

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
              'Não foi possível carregar os serviços do agendamento. '
              'Tente novamente.',
        ),
      );
    }
  }

  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) {
    throw UnimplementedError('createMany() será implementado em etapa futura.');
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) {
    throw UnimplementedError(
      'deleteByAppointment() será implementado em etapa futura.',
    );
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }

  ParseObject _appointmentPointer(String appointmentId) {
    return ParseObject(_appointmentClassName)..objectId = appointmentId;
  }
}
