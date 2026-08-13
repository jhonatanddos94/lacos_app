import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/network/parse_temporary_error_mapper.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/infrastructure/errors/parse_appointment_error_mapper.dart';
import 'package:lacos_app/features/appointments/infrastructure/mappers/appointment_mapper.dart';
import 'package:lacos_app/features/salon/domain/entities/salon.dart';
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
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _findByDateRangeInternal(
      startInclusive: dayStart,
      endExclusive: dayEnd,
    );
  }

  @override
  Future<List<Appointment>> findByDateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  }) async {
    return _findByDateRangeInternal(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      statuses: statuses,
    );
  }

  Future<List<Appointment>> _findByDateRangeInternal({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  }) async {
    try {
      final salon = await _requireCurrentSalon();

      final rangeStart = DateTime(
        startInclusive.year,
        startInclusive.month,
        startInclusive.day,
      );
      final rangeEnd = DateTime(
        endExclusive.year,
        endExclusive.month,
        endExclusive.day,
      );

      if (!rangeEnd.isAfter(rangeStart)) {
        return const [];
      }

      final query =
          QueryBuilder<ParseObject>(ParseObject(_appointmentClassName))
            ..whereEqualTo('salon', _salonPointer(salon.id))
            ..whereEqualTo('isActive', true)
            ..whereGreaterThanOrEqualsTo('startAt', rangeStart)
            ..whereLessThan('startAt', rangeEnd)
            ..orderByAscending('startAt');

      if (statuses != null) {
        final statusValues = statuses
            .map((status) => status.toParse())
            .toList(growable: false);
        if (statusValues.isNotEmpty) {
          query.whereContainedIn('status', statusValues);
        }
      }

      final response = await query.query<ParseObject>();
      _throwIfQueryFailed(response);

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
      final salon = await _requireCurrentSalon();

      final rangeStart = DateTime(start.year, start.month, start.day);
      final rangeEnd = DateTime(
        end.year,
        end.month,
        end.day,
      ).add(const Duration(days: 1));

      final query =
          QueryBuilder<ParseObject>(ParseObject(_appointmentClassName))
            ..whereEqualTo('salon', _salonPointer(salon.id))
            ..whereEqualTo('isActive', true)
            ..whereGreaterThanOrEqualsTo('startAt', rangeStart)
            ..whereLessThan('startAt', rangeEnd)
            ..orderByAscending('startAt');

      final response = await query.query<ParseObject>();
      _throwIfQueryFailed(response);

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

      final salon = await _requireCurrentSalon();

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
      _throwIfSaveFailed(response);

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
      final salon = await _requireCurrentSalon();

      final parseAppointment = await _fetchParseAppointmentById(appointmentId);
      final appointment = _mapper.toDomain(parseAppointment);

      if (appointment.salonId != salon.id) {
        throw const AppointmentNotFoundException();
      }

      return appointment;
    } on AppointmentNotFoundException {
      rethrow;
    } on StateError {
      rethrow;
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: 'Não foi possível carregar o agendamento. Tente novamente.',
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
      final salon = await _requireCurrentSalon();

      final parseAppointment = await _fetchParseAppointmentById(appointmentId);
      final appointment = _mapper.toDomain(parseAppointment);

      if (appointment.salonId != salon.id) {
        throw const AppointmentNotFoundException();
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
      _throwIfSaveFailed(response);

      return _mapper.toDomain(parseAppointment);
    } on AppointmentAlreadyCanceledException {
      rethrow;
    } on AppointmentCannotCancelCompletedException {
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
          fallback: AppStrings.appointmentCancelError,
        ),
      );
    }
  }

  @override
  Future<Appointment> complete(String appointmentId) async {
    try {
      final salon = await _requireCurrentSalon();

      final parseAppointment = await _fetchParseAppointmentById(appointmentId);
      final appointment = _mapper.toDomain(parseAppointment);

      if (appointment.salonId != salon.id) {
        throw const AppointmentNotFoundException();
      }

      if (appointment.status == AppointmentStatus.completed) {
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
      _throwIfSaveFailed(response);

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
      final salon = await _requireCurrentSalon();

      final parseAppointment = await _fetchParseAppointmentById(appointment.id);
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
      _throwIfSaveFailed(response);

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
  Future<Appointment?> findNextByClientId(
    String clientId, {
    required DateTime now,
  }) async {
    if (clientId.trim().isEmpty) {
      return null;
    }

    try {
      final salon = await _requireCurrentSalon();

      final query =
          QueryBuilder<ParseObject>(ParseObject(_appointmentClassName))
            ..whereEqualTo('salon', _salonPointer(salon.id))
            ..whereEqualTo('client', _clientPointer(clientId))
            ..whereEqualTo('isActive', true)
            ..whereContainedIn('status', [
              AppointmentStatus.pending.toParse(),
              AppointmentStatus.confirmed.toParse(),
            ])
            ..whereGreaterThan('endAt', now)
            ..orderByAscending('startAt')
            ..setLimit(1);

      final response = await query.query<ParseObject>();
      _throwIfQueryFailed(response);

      final results = response.results;
      if (results == null || results.isEmpty) {
        return null;
      }

      return _mapper.toDomain(results.first as ParseObject);
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
  Future<List<Appointment>> findCanceledByClientId(String clientId) async {
    if (clientId.trim().isEmpty) {
      return const [];
    }

    try {
      final salon = await _requireCurrentSalon();

      final query =
          QueryBuilder<ParseObject>(ParseObject(_appointmentClassName))
            ..whereEqualTo('salon', _salonPointer(salon.id))
            ..whereEqualTo('client', _clientPointer(clientId))
            ..whereEqualTo('isActive', true)
            ..whereEqualTo('status', AppointmentStatus.canceled.toParse())
            ..orderByDescending('startAt');

      final response = await query.query<ParseObject>();
      _throwIfQueryFailed(response);

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

  Future<Salon> _requireCurrentSalon() async {
    final salon = await _salonRepository.getCurrentSalon();
    if (salon == null) {
      throw StateError(
        'Não encontramos seu salão. Cadastre um salão antes de continuar.',
      );
    }

    return salon;
  }

  void _throwIfQueryFailed(ParseResponse response) {
    if (!response.success) {
      throw FormatException(_errorMapper.toMessage(response.error));
    }
  }

  void _throwIfSaveFailed(ParseResponse response) {
    if (!response.success) {
      throw FormatException(
        _errorMapper.toMessage(response.error, forSave: true),
      );
    }
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

  Future<ParseObject> _fetchParseAppointmentById(String appointmentId) async {
    if (appointmentId.trim().isEmpty) {
      throw const AppointmentNotFoundException();
    }

    final parseAppointment = ParseObject(_appointmentClassName)
      ..objectId = appointmentId;

    ParseResponse response;
    try {
      response = await parseAppointment.getObject(appointmentId);
    } on Object catch (error) {
      throw FormatException(
        ParseTemporaryErrorMapper.messageForThrowable(
          error,
          fallback: 'Não foi possível carregar o agendamento. Tente novamente.',
        ),
      );
    }

    if (response.error?.code == ParseError.objectNotFound) {
      throw const AppointmentNotFoundException();
    }

    if (!response.success) {
      throw FormatException(_errorMapper.toMessage(response.error));
    }

    final results = response.results;
    if (results == null || results.isEmpty) {
      throw FormatException(
        'Não foi possível carregar o agendamento. Tente novamente.',
      );
    }

    final fetched = results.first as ParseObject;
    if (!_isFetchedAppointmentHydrated(fetched)) {
      throw FormatException(
        'Não foi possível carregar o agendamento. Tente novamente.',
      );
    }

    return fetched;
  }

  bool _isFetchedAppointmentHydrated(ParseObject object) {
    return object.get<ParseObject>('salon')?.objectId?.isNotEmpty == true &&
        object.get<ParseObject>('client')?.objectId?.isNotEmpty == true &&
        object.get<ParseObject>('professional')?.objectId?.isNotEmpty == true &&
        object.get<DateTime>('startAt') != null &&
        object.get<DateTime>('endAt') != null &&
        object.get<String>('status')?.isNotEmpty == true;
  }
}
