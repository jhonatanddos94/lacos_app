import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/salon/domain/repositories/salon_repository.dart';
import 'package:lacos_app/features/working_hours/domain/repositories/professional_working_hours_repository.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_day_time_window.dart';
import 'package:lacos_app/features/working_hours/domain/services/working_hours_resolver.dart';
import 'package:lacos_app/features/working_hours/domain/value_objects/working_day_availability.dart';

/// Valida disponibilidade de agendamento contra horários persistidos da Professional.
class AppointmentScheduleValidator {
  const AppointmentScheduleValidator({
    required SalonRepository salonRepository,
    required ProfessionalWorkingHoursRepository workingHoursRepository,
    required AvailabilityEngine availabilityEngine,
  }) : _salonRepository = salonRepository,
       _workingHoursRepository = workingHoursRepository,
       _availabilityEngine = availabilityEngine;

  final SalonRepository _salonRepository;
  final ProfessionalWorkingHoursRepository _workingHoursRepository;
  final AvailabilityEngine _availabilityEngine;

  Future<WorkingDayAvailability> resolveDayAvailability({
    required String professionalId,
    required DateTime day,
  }) async {
    final salon = await _salonRepository.getCurrentSalon();
    if (salon == null) {
      throw StateError(
        'Não encontramos seu salão. Cadastre um salão antes de continuar.',
      );
    }

    final week = await _workingHoursRepository.findWeek(
      salonId: salon.id,
      professionalId: professionalId,
    );

    return WorkingHoursResolver.resolve(
      day: day,
      configuredWeek: week,
    );
  }

  Future<void> ensureIntervalIsAvailable({
    required DateTime startAt,
    required DateTime endAt,
    required String professionalId,
    required List<Appointment> existingAppointments,
    String? ignoreAppointmentId,
    bool enforceWorkingHoursWindow = true,
  }) async {
    final normalizedDay = DateTime(startAt.year, startAt.month, startAt.day);
    final dayAvailability = await resolveDayAvailability(
      professionalId: professionalId,
      day: normalizedDay,
    );

    if (enforceWorkingHoursWindow) {
      if (!dayAvailability.isWorking) {
        throw const AppointmentUnavailableException();
      }

      final openingTime = dayAvailability.openingTimeOn(normalizedDay);
      final closingTime = dayAvailability.closingTimeOn(normalizedDay);

      final isAvailable = _availabilityEngine.isIntervalAvailable(
        startAt: startAt,
        endAt: endAt,
        professionalId: professionalId,
        existingAppointments: existingAppointments,
        openingTime: openingTime,
        closingTime: closingTime,
        ignoreAppointmentId: ignoreAppointmentId,
      );

      if (!isAvailable) {
        throw const AppointmentUnavailableException();
      }
      return;
    }

    final hasConflict = _availabilityEngine.hasScheduleConflict(
      startAt: startAt,
      endAt: endAt,
      professionalId: professionalId,
      existingAppointments: existingAppointments,
      ignoreAppointmentId: ignoreAppointmentId,
    );

    if (hasConflict) {
      throw const AppointmentUnavailableException();
    }
  }
}
