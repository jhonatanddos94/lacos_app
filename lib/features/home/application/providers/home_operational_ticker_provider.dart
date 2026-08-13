import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/time/app_clock.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/home/application/services/home_operational_boundary.dart';

/// Relógio operacional da Home. Testes podem overridear sem criar Timer.
final homeOperationalNowProvider = Provider<DateTime>((ref) {
  return ref.watch(homeOperationalTickerProvider);
});

/// Recomputa current/upcoming/overdue na próxima fronteira `startAt`/`endAt`.
///
/// Não dispara query remota: apenas atualiza o instante usado pelo snapshot.
final homeOperationalTickerProvider =
    NotifierProvider<HomeOperationalTicker, DateTime>(
      HomeOperationalTicker.new,
    );

class HomeOperationalTicker extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(_cancel);
    final clock = ref.watch(appClockProvider);
    final today = ref.watch(calendarTodayProvider);
    final appointments =
        ref.watch(agendaAppointmentsDisplayProvider(today)).valueOrNull ??
        const <AgendaAppointmentDisplay>[];
    _schedule(clock, appointments);
    return clock.now();
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _schedule(AppClock clock, List<AgendaAppointmentDisplay> appointments) {
    _cancel();
    final now = clock.now();
    final boundary = HomeOperationalBoundary.next(
      appointments: appointments,
      now: now,
    );
    if (boundary == null) {
      return;
    }

    var delay = boundary.difference(now);
    if (delay <= Duration.zero) {
      delay = const Duration(milliseconds: 1);
    }

    _timer = Timer(delay, () {
      state = clock.now();
      _schedule(clock, appointments);
    });
  }
}
