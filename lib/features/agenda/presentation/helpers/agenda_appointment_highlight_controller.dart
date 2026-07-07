import 'dart:async';

import 'package:lacos_app/core/config/app_durations.dart';

class AgendaAppointmentHighlightController {
  AgendaAppointmentHighlightController({
    this.highlightDuration = AppDurations.agendaHighlight,
  });

  final Duration highlightDuration;

  String? highlightedAppointmentId;
  Timer? _clearTimer;

  bool isHighlighted(String appointmentId) {
    return highlightedAppointmentId == appointmentId;
  }

  void applyHighlight({
    required String appointmentId,
    required void Function() onChanged,
  }) {
    _clearTimer?.cancel();
    highlightedAppointmentId = appointmentId;
    onChanged();
    _clearTimer = Timer(highlightDuration, () {
      if (highlightedAppointmentId != appointmentId) {
        return;
      }

      highlightedAppointmentId = null;
      onChanged();
    });
  }

  void dispose() {
    _clearTimer?.cancel();
  }
}
