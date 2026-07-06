import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
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
  static const _serviceClassName = 'Service';
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
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) async {
    if (appointmentIds.isEmpty) {
      return const [];
    }

    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final appointmentPointers = appointmentIds
          .map(_appointmentPointer)
          .toList(growable: false);

      final query = QueryBuilder<ParseObject>(
        ParseObject(_appointmentServiceClassName),
      )
        ..whereContainedIn('appointment', appointmentPointers)
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
      final createdServices = <AppointmentService>[];

      for (final service in services) {
        final parseAppointmentService = ParseObject(_appointmentServiceClassName)
          ..set<ParseObject>('appointment', _appointmentPointer(appointmentId))
          ..set<ParseObject>('service', _servicePointer(service.serviceId))
          ..set<ParseObject>('salon', _salonPointer(salon.id))
          ..set<ParseUser>('owner', owner)
          ..set<num>('priceAtBooking', service.priceAtBooking ?? 0)
          ..set<int>(
            'durationMinutesAtBooking',
            service.durationMinutesAtBooking,
          )
          ..set<int>('displayOrder', service.displayOrder)
          ..set<bool>('isActive', true);

        final response = await parseAppointmentService.save();
        if (!response.success) {
          throw FormatException(
            _errorMapper.toMessage(response.error, forSave: true),
          );
        }

        createdServices.add(_mapper.toDomain(parseAppointmentService));
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
          fallback: AppStrings.appointmentServiceSaveError,
        ),
      );
    }
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) {
    throw UnimplementedError(
      'deleteByAppointment() será implementado em etapa futura.',
    );
  }

  ParseObject _servicePointer(String serviceId) {
    return ParseObject(_serviceClassName)..objectId = serviceId;
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }

  ParseObject _appointmentPointer(String appointmentId) {
    return ParseObject(_appointmentClassName)..objectId = appointmentId;
  }
}
