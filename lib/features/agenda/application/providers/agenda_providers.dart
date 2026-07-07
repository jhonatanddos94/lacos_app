import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/loaders/agenda_appointments_display_loader.dart';
import 'package:lacos_app/features/agenda/application/loaders/agenda_calendar_appointment_days_loader.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_calendar_view.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/services/application/providers/service_providers.dart';

final agendaAppointmentsDisplayLoaderProvider =
    Provider<AgendaAppointmentsDisplayLoader>((ref) {
      return AgendaAppointmentsDisplayLoader(
        appointmentRepository: ref.watch(appointmentRepositoryProvider),
        appointmentServiceRepository: ref.watch(
          appointmentServiceRepositoryProvider,
        ),
        clientRepository: ref.watch(clientRepositoryProvider),
        serviceRepository: ref.watch(serviceRepositoryProvider),
      );
    });

final agendaAppointmentsDisplayProvider =
    FutureProvider.family<List<AgendaAppointmentDisplay>, AgendaDay>((
      ref,
      day,
    ) {
      final loader = ref.watch(agendaAppointmentsDisplayLoaderProvider);
      return loader.loadForDay(day.toDateTime());
    });

final agendaCalendarAppointmentDaysLoaderProvider =
    Provider<AgendaCalendarAppointmentDaysLoader>((ref) {
      return AgendaCalendarAppointmentDaysLoader(
        appointmentRepository: ref.watch(appointmentRepositoryProvider),
      );
    });

final agendaCalendarAppointmentDaysProvider =
    FutureProvider.family<Set<DateTime>, AgendaCalendarView>((ref, view) {
      final loader = ref.watch(agendaCalendarAppointmentDaysLoaderProvider);
      return loader.loadForMonth(year: view.year, month: view.month);
    });
