import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/scheduling/scheduling_defaults.dart';

class AvailabilityEngine {
  const AvailabilityEngine();

  List<DateTime> calculateAvailableStartTimes({
    required DateTime day,
    required int durationMinutes,
    required List<Appointment> existingAppointments,
    required DateTime openingTime,
    required DateTime closingTime,
    DateTime? notBefore,
    String? ignoreAppointmentId,
  }) {
    if (durationMinutes <= 0) {
      return const [];
    }

    final normalizedDay = _normalizeDate(day);
    final openAt = _combineDateAndTime(normalizedDay, openingTime);
    final closeAt = _combineDateAndTime(normalizedDay, closingTime);

    if (!openAt.isBefore(closeAt)) {
      return const [];
    }

    final totalOpenMinutes = closeAt.difference(openAt).inMinutes;
    if (durationMinutes > totalOpenMinutes) {
      return const [];
    }

    final blockingAppointments = existingAppointments
        .where(_isBlockingAppointment)
        .where(
          (appointment) =>
              ignoreAppointmentId == null ||
              appointment.id != ignoreAppointmentId,
        )
        .toList(growable: false);

    final availableStartTimes = <DateTime>[];
    var candidateStart = openAt;

    while (true) {
      final candidateEnd = candidateStart.add(
        Duration(minutes: durationMinutes),
      );

      if (candidateEnd.isAfter(closeAt)) {
        break;
      }

      if (notBefore != null && candidateStart.isBefore(notBefore)) {
        candidateStart = candidateStart.add(
          Duration(minutes: SchedulingDefaults.slotIntervalMinutes),
        );
        continue;
      }

      if (!_hasConflict(
        newStart: candidateStart,
        newEnd: candidateEnd,
        appointments: blockingAppointments,
      )) {
        availableStartTimes.add(candidateStart);
      }

      candidateStart = candidateStart.add(
        Duration(minutes: SchedulingDefaults.slotIntervalMinutes),
      );
    }

    return availableStartTimes;
  }

  bool isIntervalAvailable({
    required DateTime startAt,
    required DateTime endAt,
    required String professionalId,
    required List<Appointment> existingAppointments,
    required DateTime openingTime,
    required DateTime closingTime,
    String? ignoreAppointmentId,
  }) {
    if (!_isIntervalWithinWorkingHours(
      startAt: startAt,
      endAt: endAt,
      openingTime: openingTime,
      closingTime: closingTime,
    )) {
      return false;
    }

    return !hasScheduleConflict(
      startAt: startAt,
      endAt: endAt,
      professionalId: professionalId,
      existingAppointments: existingAppointments,
      ignoreAppointmentId: ignoreAppointmentId,
    );
  }

  bool hasScheduleConflict({
    required DateTime startAt,
    required DateTime endAt,
    required String professionalId,
    required List<Appointment> existingAppointments,
    String? ignoreAppointmentId,
  }) {
    if (!startAt.isBefore(endAt)) {
      return true;
    }

    final professionalAppointments = existingAppointments
        .where((appointment) => appointment.professionalId == professionalId)
        .where(_isBlockingAppointment)
        .where(
          (appointment) =>
              ignoreAppointmentId == null ||
              appointment.id != ignoreAppointmentId,
        )
        .toList(growable: false);

    return _hasConflict(
      newStart: startAt,
      newEnd: endAt,
      appointments: professionalAppointments,
    );
  }

  bool _isIntervalWithinWorkingHours({
    required DateTime startAt,
    required DateTime endAt,
    required DateTime openingTime,
    required DateTime closingTime,
  }) {
    if (!startAt.isBefore(endAt)) {
      return false;
    }

    final normalizedDay = _normalizeDate(startAt);
    final openAt = _combineDateAndTime(normalizedDay, openingTime);
    final closeAt = _combineDateAndTime(normalizedDay, closingTime);

    return !startAt.isBefore(openAt) && !endAt.isAfter(closeAt);
  }

  bool _isBlockingAppointment(Appointment appointment) {
    return appointment.isActive &&
        appointment.status != AppointmentStatus.canceled;
  }

  bool _hasConflict({
    required DateTime newStart,
    required DateTime newEnd,
    required List<Appointment> appointments,
  }) {
    for (final appointment in appointments) {
      final overlaps =
          newStart.isBefore(appointment.endAt) &&
          newEnd.isAfter(appointment.startAt);

      if (overlaps) {
        return true;
      }
    }

    return false;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _combineDateAndTime(DateTime day, DateTime time) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }
}
