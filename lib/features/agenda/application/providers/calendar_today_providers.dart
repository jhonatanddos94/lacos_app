import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/time/app_clock.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';

/// "Hoje" civil local. Testes podem overridear este provider sem criar Timer.
final calendarTodayProvider = Provider<AgendaDay>((ref) {
  return ref.watch(calendarTodayTickerProvider);
});

/// Atualiza [calendarTodayProvider] na próxima meia-noite local.
final calendarTodayTickerProvider =
    NotifierProvider<CalendarTodayTicker, AgendaDay>(CalendarTodayTicker.new);

class CalendarTodayTicker extends Notifier<AgendaDay> {
  Timer? _timer;

  @override
  AgendaDay build() {
    ref.onDispose(_cancel);
    final clock = ref.watch(appClockProvider);
    _schedule(clock);
    return AgendaDay.from(clock.now());
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _schedule(AppClock clock) {
    _cancel();
    final now = clock.now();
    var delay = durationUntilNextLocalMidnight(now);
    if (delay <= Duration.zero) {
      delay = const Duration(milliseconds: 1);
    }

    _timer = Timer(delay, () {
      state = AgendaDay.from(clock.now());
      _schedule(clock);
    });
  }
}
