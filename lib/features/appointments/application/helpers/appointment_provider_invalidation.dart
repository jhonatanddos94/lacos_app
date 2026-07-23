import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details_query.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_details_providers.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';

void invalidateAppointmentDetailsProviders(
  WidgetRef ref, {
  required String appointmentId,
  required DateTime day,
}) {
  ref.invalidate(
    appointmentDetailsProvider(
      AppointmentDetailsQuery(appointmentId: appointmentId, day: day),
    ),
  );
  ref.invalidate(appointmentServicesByAppointmentProvider(appointmentId));
}

void invalidateAppointmentAgendaProviders(
  WidgetRef ref, {
  required AgendaDay day,
}) {
  ref.invalidate(agendaAppointmentsDisplayProvider(day));
  ref.invalidate(appointmentsByDayProvider(day));
}

void invalidateAppointmentAfterUpdate(
  WidgetRef ref, {
  required String appointmentId,
  required DateTime updatedDay,
  DateTime? originalDay,
}) {
  invalidateAppointmentDetailsProviders(
    ref,
    appointmentId: appointmentId,
    day: updatedDay,
  );

  invalidateAppointmentAgendaProviders(ref, day: AgendaDay.from(updatedDay));

  if (originalDay != null && !_isSameDay(originalDay, updatedDay)) {
    invalidateAppointmentDetailsProviders(
      ref,
      appointmentId: appointmentId,
      day: originalDay,
    );
    invalidateAppointmentAgendaProviders(ref, day: AgendaDay.from(originalDay));
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
