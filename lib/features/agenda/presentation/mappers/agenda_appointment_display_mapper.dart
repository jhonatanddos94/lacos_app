import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_operational_state.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';

class AgendaAppointmentDisplayMapper {
  const AgendaAppointmentDisplayMapper._();

  static List<TodayScheduleAppointment> toScheduleItems(
    List<AgendaAppointmentDisplay> appointments,
    DateTime selectedDay, {
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final sorted = [...appointments]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final nextAppointmentId = _findNextAppointmentId(
      sorted,
      selectedDay,
      now: referenceNow,
    );

    return sorted
        .map(
          (appointment) => toScheduleItem(
            appointment,
            isNext: appointment.appointmentId == nextAppointmentId,
            now: referenceNow,
          ),
        )
        .toList(growable: false);
  }

  static TodayScheduleAppointment toScheduleItem(
    AgendaAppointmentDisplay appointment, {
    required bool isNext,
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final operationalState = appointment.operationalState(now: referenceNow);

    return TodayScheduleAppointment(
      startTime: formatAppointmentClockTime(appointment.startAt),
      endTime: formatAppointmentClockTime(appointment.endAt),
      clientName: appointment.clientName,
      clientPhotoUrl: appointment.clientPhotoUrl,
      serviceName: appointment.servicesSummary,
      durationLabel: formatAppointmentDuration(
        appointment.startAt,
        appointment.endAt,
      ),
      status: _mapScheduleStatus(
        appointment,
        isNext: isNext,
        operationalState: operationalState,
      ),
      operationalState: operationalState,
      statusSubtitle: _statusSubtitle(appointment),
      statusDetail: _statusDetail(appointment),
    );
  }

  static String? _statusSubtitle(AgendaAppointmentDisplay appointment) {
    if (appointment.status != AppointmentStatus.canceled) {
      return null;
    }

    return formatAppointmentCanceledByLabel(appointment.canceledBy);
  }

  static String? _statusDetail(AgendaAppointmentDisplay appointment) {
    if (appointment.status != AppointmentStatus.canceled) {
      return null;
    }

    final reason = appointment.cancellationReason?.trim();
    if (reason == null || reason.isEmpty) {
      return null;
    }

    return reason;
  }

  static String? nextStartTime(
    List<AgendaAppointmentDisplay> appointments,
    DateTime day, {
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final sorted = [...appointments]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final nextId = _findNextAppointmentId(
      sorted,
      day,
      now: referenceNow,
    );
    if (nextId == null) return null;

    final nextAppointment = sorted.firstWhere(
      (appointment) => appointment.appointmentId == nextId,
    );

    return formatAppointmentClockTime(nextAppointment.startAt);
  }

  static String? _findNextAppointmentId(
    List<AgendaAppointmentDisplay> appointments,
    DateTime selectedDay, {
    required DateTime now,
  }) {
    if (normalizeAppointmentDate(selectedDay).isBefore(normalizeAppointmentDate(now))) {
      return null;
    }

    for (final appointment in appointments) {
      final operationalState = appointment.operationalState(now: now);

      if (operationalState == AppointmentOperationalState.upcoming) {
        return appointment.appointmentId;
      }
    }

    return null;
  }

  static ScheduleStatus _mapScheduleStatus(
    AgendaAppointmentDisplay appointment, {
    required bool isNext,
    required AppointmentOperationalState operationalState,
  }) {
    if (isNext && operationalState == AppointmentOperationalState.upcoming) {
      return ScheduleStatus.next;
    }

    return switch (appointment.status) {
      AppointmentStatus.completed => ScheduleStatus.completed,
      AppointmentStatus.confirmed => ScheduleStatus.confirmed,
      AppointmentStatus.pending => ScheduleStatus.pending,
      AppointmentStatus.canceled => ScheduleStatus.canceled,
    };
  }
}
