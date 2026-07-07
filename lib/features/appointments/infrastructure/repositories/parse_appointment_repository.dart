import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:flutter/foundation.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
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
  static const _clientClassName = 'Client';
  static const _professionalClassName = 'Professional';
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
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final rangeStart = DateTime(start.year, start.month, start.day);
      final rangeEnd = DateTime(
        end.year,
        end.month,
        end.day,
      ).add(const Duration(days: 1));

      final query = QueryBuilder<ParseObject>(
        ParseObject(_appointmentClassName),
      )
        ..whereEqualTo('salon', _salonPointer(salon.id))
        ..whereEqualTo('isActive', true)
        ..whereGreaterThanOrEqualsTo('startAt', rangeStart)
        ..whereLessThan('startAt', rangeEnd)
        ..orderByAscending('startAt');

      final response = await query.query<ParseObject>();
      if (!response.success) {
        throw FormatException(_errorMapper.toMessage(response.error));
      }

      final results = response.results;
      if (results == null || results.isEmpty) {
        return const {};
      }

      final daysWithAppointments = <DateTime>{};
      for (final parseObject in results.whereType<ParseObject>()) {
        final appointment = _mapper.toDomain(parseObject);
        if (!appointment.status.countsForCalendarIndicator) {
          continue;
        }

        daysWithAppointments.add(
          DateTime(
            appointment.startAt.year,
            appointment.startAt.month,
            appointment.startAt.day,
          ),
        );
      }

      return daysWithAppointments;
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
  Future<Appointment> create(Appointment appointment) async {
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
      final parseAppointment = ParseObject(_appointmentClassName)
        ..set<ParseObject>('client', _clientPointer(appointment.clientId))
        ..set<ParseObject>(
          'professional',
          _professionalPointer(appointment.professionalId),
        )
        ..set<ParseObject>('salon', _salonPointer(salon.id))
        ..set<ParseUser>('owner', owner)
        ..set<DateTime>('startAt', appointment.startAt)
        ..set<DateTime>('endAt', appointment.endAt)
        ..set<String>('status', appointment.status.toParse())
        ..set<bool>('isActive', true);

      final notes = appointment.notes;
      if (notes != null && notes.isNotEmpty) {
        parseAppointment.set<String>('notes', notes);
      }

      final response = await parseAppointment.save();
      if (!response.success) {
        throw FormatException(
          _errorMapper.toMessage(response.error, forSave: true),
        );
      }

      return _mapper.toDomain(parseAppointment);
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForSaveThrowable(
          error,
          fallback: AppStrings.appointmentSaveError,
        ),
      );
    }
  }

  @override
  Future<Appointment> findById(String appointmentId) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final parseAppointment = await _fetchParseAppointment(appointmentId);
      final appointment = _mapper.toDomain(parseAppointment);

      if (appointment.salonId != salon.id) {
        throw StateError(
          'Não foi possível carregar o agendamento. Tente novamente.',
        );
      }

      return appointment;
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback:
              'Não foi possível carregar o agendamento. Tente novamente.',
        ),
      );
    }
  }

  @override
  Future<Appointment> cancel({
    required String appointmentId,
    required AppointmentCanceledBy canceledBy,
    String? cancellationReason,
  }) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final parseAppointment = await _fetchParseAppointment(appointmentId);
      final appointment = _mapper.toDomain(parseAppointment);

      if (appointment.salonId != salon.id) {
        throw StateError(
          'Não foi possível cancelar o agendamento. Tente novamente.',
        );
      }

      if (appointment.status == AppointmentStatus.completed) {
        throw const AppointmentCannotCancelCompletedException();
      }

      if (appointment.status == AppointmentStatus.canceled) {
        throw const AppointmentAlreadyCanceledException();
      }

      _mapper.applyCancellation(
        object: parseAppointment,
        canceledBy: canceledBy,
        canceledAt: DateTime.now(),
        cancellationReason: cancellationReason,
      );

      final response = await parseAppointment.save();
      if (!response.success) {
        throw FormatException(
          _errorMapper.toMessage(response.error, forSave: true),
        );
      }

      return _mapper.toDomain(parseAppointment);
    } on AppointmentAlreadyCanceledException {
      rethrow;
    } on AppointmentCannotCancelCompletedException {
      rethrow;
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForSaveThrowable(
          error,
          fallback: AppStrings.appointmentCancelError,
        ),
      );
    }
  }

  @override
  Future<Appointment> complete(String appointmentId) async {
    try {
      debugPrint('[AppointmentComplete] repository complete start');
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final parseAppointment = await _fetchParseAppointmentForComplete(
        appointmentId,
      );
      final appointment = _mapper.toDomain(parseAppointment);

      if (appointment.salonId != salon.id) {
        throw const AppointmentNotFoundException();
      }

      if (appointment.status == AppointmentStatus.completed) {
        debugPrint('[AppointmentComplete] repository complete already completed');
        return appointment;
      }

      if (!appointment.status.canBeCompleted) {
        throw const AppointmentCannotCompleteException();
      }

      final completedAt = DateTime.now();
      parseAppointment
        ..set<String>('status', AppointmentStatus.completed.toParse())
        ..set<DateTime>('completedAt', completedAt);

      final response = await parseAppointment.save();
      if (!response.success) {
        throw FormatException(
          _errorMapper.toMessage(response.error, forSave: true),
        );
      }

      debugPrint('[AppointmentComplete] repository complete saved');
      return _mapper.toDomain(parseAppointment);
    } on AppointmentNotFoundException {
      rethrow;
    } on AppointmentCannotCompleteException {
      rethrow;
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForSaveThrowable(
          error,
          fallback: AppStrings.appointmentCompleteError,
        ),
      );
    }
  }

  @override
  Future<Appointment> update(Appointment appointment) async {
    try {
      final salon = await _salonRepository.getCurrentSalon();
      if (salon == null) {
        throw StateError(
          'Não encontramos seu salão. Cadastre um salão antes de continuar.',
        );
      }

      final parseAppointment = await _fetchParseAppointment(appointment.id);
      final existingAppointment = _mapper.toDomain(parseAppointment);

      if (existingAppointment.salonId != salon.id) {
        throw const AppointmentNotFoundException();
      }

      if (!existingAppointment.isActive) {
        throw const AppointmentNotFoundException();
      }

      if (!existingAppointment.status.canBeEdited) {
        throw const AppointmentCannotEditException();
      }

      _mapper.applyUpdate(
        object: parseAppointment,
        clientId: appointment.clientId,
        professionalId: appointment.professionalId,
        startAt: appointment.startAt,
        endAt: appointment.endAt,
        notes: appointment.notes,
        clientPointer: _clientPointer,
        professionalPointer: _professionalPointer,
      );

      final response = await parseAppointment.save();
      if (!response.success) {
        throw FormatException(
          _errorMapper.toMessage(response.error, forSave: true),
        );
      }

      return _mapper.toDomain(parseAppointment);
    } on AppointmentCannotEditException {
      rethrow;
    } on AppointmentNotFoundException {
      rethrow;
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForSaveThrowable(
          error,
          fallback: AppStrings.appointmentUpdateError,
        ),
      );
    }
  }

  @override
  Future<void> delete(String appointmentId) {
    throw UnimplementedError('delete() será implementado em etapa futura.');
  }

  ParseObject _clientPointer(String clientId) {
    return ParseObject(_clientClassName)..objectId = clientId;
  }

  ParseObject _professionalPointer(String professionalId) {
    return ParseObject(_professionalClassName)..objectId = professionalId;
  }

  ParseObject _salonPointer(String salonId) {
    return ParseObject(_salonClassName)..objectId = salonId;
  }

  Future<ParseObject> _fetchParseAppointment(String appointmentId) async {
    return _fetchParseAppointmentById(appointmentId);
  }

  Future<ParseObject> _fetchParseAppointmentForComplete(
    String appointmentId,
  ) async {
    try {
      return await _fetchParseAppointmentById(appointmentId);
    } on FormatException {
      throw const AppointmentNotFoundException();
    }
  }

  Future<ParseObject> _fetchParseAppointmentById(String appointmentId) async {
    final parseAppointment = ParseObject(_appointmentClassName)
      ..objectId = appointmentId;

    try {
      await parseAppointment.fetch();
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback:
              'Não foi possível carregar o agendamento. Tente novamente.',
        ),
      );
    }

    return parseAppointment;
  }
}
