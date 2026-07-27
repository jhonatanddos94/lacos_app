import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details_query.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_details_providers.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_next_appointment_providers.dart';
import 'package:lacos_app/features/service_records/application/providers/service_record_providers.dart';

void invalidateClientNextAppointment(WidgetRef ref, String clientId) {
  if (clientId.trim().isEmpty) {
    return;
  }

  ref.invalidate(clientNextAppointmentProvider(clientId));
}

void invalidateClientNextAppointmentsForChange(
  WidgetRef ref, {
  String? originalClientId,
  String? updatedClientId,
}) {
  final clientIds = <String>{};

  if (originalClientId != null && originalClientId.trim().isNotEmpty) {
    clientIds.add(originalClientId);
  }

  if (updatedClientId != null && updatedClientId.trim().isNotEmpty) {
    clientIds.add(updatedClientId);
  }

  for (final clientId in clientIds) {
    invalidateClientNextAppointment(ref, clientId);
  }
}

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

void invalidateAppointmentAfterCreate(
  WidgetRef ref, {
  required String clientId,
  required DateTime day,
}) {
  invalidateAppointmentAgendaProviders(ref, day: AgendaDay.from(day));
  invalidateClientNextAppointment(ref, clientId);
}

void invalidateAppointmentAfterUpdate(
  WidgetRef ref, {
  required String appointmentId,
  required DateTime updatedDay,
  DateTime? originalDay,
  String? originalClientId,
  String? updatedClientId,
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

  invalidateClientNextAppointmentsForChange(
    ref,
    originalClientId: originalClientId,
    updatedClientId: updatedClientId ?? originalClientId,
  );
}

void invalidateAppointmentAfterCancellation(
  WidgetRef ref, {
  required String appointmentId,
  required String clientId,
  required DateTime day,
}) {
  invalidateAppointmentAfterUpdate(
    ref,
    appointmentId: appointmentId,
    updatedDay: day,
    originalClientId: clientId,
    updatedClientId: clientId,
  );
}

void invalidateAppointmentAfterCompletion(
  WidgetRef ref, {
  required String appointmentId,
  required String clientId,
  required DateTime day,
}) {
  invalidateAppointmentAfterUpdate(
    ref,
    appointmentId: appointmentId,
    updatedDay: day,
    originalClientId: clientId,
    updatedClientId: clientId,
  );
  ref.invalidate(serviceRecordByAppointmentProvider(appointmentId));
  ref.invalidate(serviceRecordsByClientProvider(clientId));
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
