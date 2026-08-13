import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/home/application/models/home_today_snapshot.dart';
import 'package:lacos_app/features/home/application/providers/home_operational_ticker_provider.dart';

/// Observa a Agenda do dia atual. Não dispara query própria.
final homeTodayAgendaProvider =
    Provider<AsyncValue<List<AgendaAppointmentDisplay>>>((ref) {
      final today = ref.watch(calendarTodayProvider);
      return ref.watch(agendaAppointmentsDisplayProvider(today));
    });

final homeTodaySnapshotProvider = Provider<AsyncValue<HomeTodaySnapshot>>((
  ref,
) {
  final agenda = ref.watch(homeTodayAgendaProvider);
  final now = ref.watch(homeOperationalNowProvider);
  return agenda.whenData(
    (appointments) =>
        HomeTodaySnapshot.fromAppointments(appointments, now: now),
  );
});

final homeTodaySummaryProvider = Provider<AsyncValue<AgendaOperationalSummary>>(
  (ref) {
    return ref.watch(homeTodaySnapshotProvider).whenData((snapshot) {
      return snapshot.summary;
    });
  },
);

final homeNextAppointmentProvider =
    Provider<AsyncValue<AgendaAppointmentDisplay?>>((ref) {
      return ref.watch(homeTodaySnapshotProvider).whenData((snapshot) {
        return snapshot.nextAppointment;
      });
    });

final homeAttentionProvider =
    Provider<AsyncValue<List<AgendaAppointmentDisplay>>>((ref) {
      return ref.watch(homeTodaySnapshotProvider).whenData((snapshot) {
        return snapshot.overdueAppointments;
      });
    });
