import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/features/appointments/application/models/updated_appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class UpdateAppointmentParams {
  const UpdateAppointmentParams({
    required this.appointmentId,
    required this.clientId,
    required this.professionalId,
    required this.services,
    required this.startAt,
    required this.endAt,
    this.notes,
  });

  final String appointmentId;
  final String clientId;
  final String professionalId;
  final List<Service> services;
  final DateTime startAt;
  final DateTime endAt;
  final String? notes;
}

class UpdateAppointmentUseCase {
  const UpdateAppointmentUseCase({
    required AppointmentRepository appointmentRepository,
    required AppointmentServiceRepository appointmentServiceRepository,
    required AvailabilityEngine availabilityEngine,
  }) : _appointmentRepository = appointmentRepository,
       _appointmentServiceRepository = appointmentServiceRepository,
       _availabilityEngine = availabilityEngine;

  static const _salonOpeningHour = 9;
  static const _salonClosingHour = 18;

  final AppointmentRepository _appointmentRepository;
  final AppointmentServiceRepository _appointmentServiceRepository;
  final AvailabilityEngine _availabilityEngine;

  Future<UpdatedAppointment> call(UpdateAppointmentParams params) async {
    final existingAppointment = await _appointmentRepository.findById(
      params.appointmentId,
    );

    if (!existingAppointment.isActive) {
      throw const AppointmentNotFoundException();
    }

    if (!existingAppointment.status.canBeEdited) {
      throw const AppointmentCannotEditException();
    }

    _validate(
      clientId: params.clientId,
      professionalId: params.professionalId,
      services: params.services,
      startAt: params.startAt,
      endAt: params.endAt,
      notes: params.notes,
    );

    final freshDayAppointments = await _appointmentRepository.findByDay(
      DateTime(params.startAt.year, params.startAt.month, params.startAt.day),
    );

    _ensureIntervalIsAvailable(
      appointmentId: params.appointmentId,
      startAt: params.startAt,
      endAt: params.endAt,
      professionalId: params.professionalId,
      existingAppointments: freshDayAppointments,
    );

    final normalizedNotes = _normalizeNotes(params.notes);
    final replacementServices = _buildAppointmentServices(
      appointmentId: existingAppointment.id,
      services: params.services,
      salonId: existingAppointment.salonId,
      ownerId: existingAppointment.ownerId,
    );

    if (replacementServices.isEmpty) {
      throw const AppointmentValidationException(
        AppointmentValidationCode.emptyServices,
      );
    }

    final updatedAppointment = await _appointmentRepository.update(
      Appointment(
        id: existingAppointment.id,
        salonId: existingAppointment.salonId,
        ownerId: existingAppointment.ownerId,
        clientId: params.clientId,
        professionalId: params.professionalId,
        startAt: params.startAt,
        endAt: params.endAt,
        status: existingAppointment.status,
        notes: normalizedNotes,
        completedAt: existingAppointment.completedAt,
        canceledAt: existingAppointment.canceledAt,
        canceledBy: existingAppointment.canceledBy,
        cancellationReason: existingAppointment.cancellationReason,
        isActive: existingAppointment.isActive,
        createdAt: existingAppointment.createdAt,
        updatedAt: DateTime.now(),
      ),
    );

    try {
      await _appointmentServiceRepository.deleteByAppointment(
        updatedAppointment.id,
      );

      final createdServices = await _appointmentServiceRepository.createMany(
        appointmentId: updatedAppointment.id,
        services: replacementServices,
      );

      if (createdServices.isEmpty) {
        throw const AppointmentServicesUpdateException();
      }

      return UpdatedAppointment(
        appointment: updatedAppointment,
        services: createdServices,
      );
    } on AppointmentServicesUpdateException {
      rethrow;
    } on Object catch (error) {
      // TODO: futuro: suporte transacional — update Appointment + sync
      // AppointmentService devem ocorrer em transação/Cloud Code.
      throw AppointmentServicesUpdateException(cause: error);
    }
  }

  void _validate({
    required String clientId,
    required String professionalId,
    required List<Service> services,
    required DateTime startAt,
    required DateTime endAt,
    String? notes,
  }) {
    if (clientId.trim().isEmpty) {
      throw const AppointmentValidationException(
        AppointmentValidationCode.emptyClientId,
      );
    }

    if (professionalId.trim().isEmpty) {
      throw const AppointmentValidationException(
        AppointmentValidationCode.emptyProfessionalId,
      );
    }

    if (services.isEmpty) {
      throw const AppointmentValidationException(
        AppointmentValidationCode.emptyServices,
      );
    }

    for (final service in services) {
      if (service.id.trim().isEmpty) {
        throw const AppointmentValidationException(
          AppointmentValidationCode.invalidServiceId,
        );
      }

      final durationMinutes = service.durationMinutes;
      if (durationMinutes == null || durationMinutes <= 0) {
        throw const AppointmentValidationException(
          AppointmentValidationCode.invalidServiceDuration,
        );
      }
    }

    if (!startAt.isBefore(endAt)) {
      throw const AppointmentValidationException(
        AppointmentValidationCode.invalidTimeRange,
      );
    }

    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null &&
        trimmedNotes.length > AppFieldLimits.appointmentNotes) {
      throw const AppointmentValidationException(
        AppointmentValidationCode.notesTooLong,
      );
    }
  }

  void _ensureIntervalIsAvailable({
    required String appointmentId,
    required DateTime startAt,
    required DateTime endAt,
    required String professionalId,
    required List<Appointment> existingAppointments,
  }) {
    final normalizedDay = DateTime(startAt.year, startAt.month, startAt.day);
    final openingTime = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      _salonOpeningHour,
    );
    final closingTime = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      _salonClosingHour,
    );

    final isAvailable = _availabilityEngine.isIntervalAvailable(
      startAt: startAt,
      endAt: endAt,
      professionalId: professionalId,
      existingAppointments: existingAppointments,
      openingTime: openingTime,
      closingTime: closingTime,
      ignoreAppointmentId: appointmentId,
    );

    if (!isAvailable) {
      throw const AppointmentUnavailableException();
    }
  }

  String? _normalizeNotes(String? notes) {
    final trimmed = notes?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  List<AppointmentService> _buildAppointmentServices({
    required String appointmentId,
    required List<Service> services,
    required String salonId,
    required String ownerId,
  }) {
    final now = DateTime.now();

    return services
        .asMap()
        .entries
        .map((entry) {
          final service = entry.value;

          return AppointmentService(
            id: '',
            appointmentId: appointmentId,
            serviceId: service.id,
            salonId: salonId,
            ownerId: ownerId,
            priceAtBooking: service.price ?? 0,
            durationMinutesAtBooking: service.durationMinutes!,
            displayOrder: entry.key,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
        })
        .toList(growable: false);
  }
}
