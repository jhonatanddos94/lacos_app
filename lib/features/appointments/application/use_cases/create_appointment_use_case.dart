import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/features/appointments/application/models/created_appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class CreateAppointmentUseCase {
  const CreateAppointmentUseCase({
    required AppointmentRepository appointmentRepository,
    required AppointmentServiceRepository appointmentServiceRepository,
    required AvailabilityEngine availabilityEngine,
  }) : _appointmentRepository = appointmentRepository,
       _appointmentServiceRepository = appointmentServiceRepository,
       _availabilityEngine = availabilityEngine;

  // TODO: futuro: substituir por horário de funcionamento do salão.
  static const _salonOpeningHour = 9;
  static const _salonClosingHour = 18;

  final AppointmentRepository _appointmentRepository;
  final AppointmentServiceRepository _appointmentServiceRepository;
  final AvailabilityEngine _availabilityEngine;

  Future<CreatedAppointment> call({
    required String clientId,
    required String professionalId,
    required List<Service> services,
    required DateTime startAt,
    required DateTime endAt,
    required List<Appointment> existingAppointments,
    String? notes,
  }) async {
    _validate(
      clientId: clientId,
      professionalId: professionalId,
      services: services,
      startAt: startAt,
      endAt: endAt,
      notes: notes,
    );

    final freshDayAppointments = await _appointmentRepository.findByDay(
      DateTime(startAt.year, startAt.month, startAt.day),
    );

    _ensureIntervalIsAvailable(
      startAt: startAt,
      endAt: endAt,
      professionalId: professionalId,
      existingAppointments: freshDayAppointments,
    );

    final normalizedNotes = _normalizeNotes(notes);
    final now = DateTime.now();
    final appointmentDraft = Appointment(
      id: '',
      salonId: '',
      ownerId: '',
      clientId: clientId,
      professionalId: professionalId,
      startAt: startAt,
      endAt: endAt,
      status: AppointmentStatus.pending,
      notes: normalizedNotes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final createdAppointment = await _appointmentRepository.create(
      appointmentDraft,
    );

    final appointmentServices = _buildAppointmentServices(
      appointmentId: createdAppointment.id,
      services: services,
    );

    try {
      final createdServices = await _appointmentServiceRepository.createMany(
        appointmentId: createdAppointment.id,
        services: appointmentServices,
      );

      return CreatedAppointment(
        appointment: createdAppointment,
        services: createdServices,
      );
    } on Object catch (error) {
      // TODO: futuro: implementar compensação/rollback para appointment órfão.
      throw AppointmentPartialSaveException(
        appointmentId: createdAppointment.id,
        cause: error,
      );
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

    if (startAt.isBefore(DateTime.now())) {
      throw const AppointmentValidationException(
        AppointmentValidationCode.startAtInPast,
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
            salonId: '',
            ownerId: '',
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
