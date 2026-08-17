import 'package:flutter/material.dart';

import 'package:lacos_app/features/appointments/domain/scheduling/scheduling_defaults.dart';

String formatWorkingHoursMinutes(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

int snapWorkingHoursMinutes(int minutes) {
  final interval = SchedulingDefaults.slotIntervalMinutes;
  final snapped = ((minutes / interval).round() * interval) % (24 * 60);
  return snapped;
}

TimeOfDay minutesToTimeOfDay(int minutes) {
  final snapped = snapWorkingHoursMinutes(minutes);
  return TimeOfDay(hour: snapped ~/ 60, minute: snapped % 60);
}

int timeOfDayToMinutes(TimeOfDay time) {
  return snapWorkingHoursMinutes(time.hour * 60 + time.minute);
}

Future<TimeOfDay?> showWorkingHoursTimePicker({
  required BuildContext context,
  required int initialMinutes,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: minutesToTimeOfDay(initialMinutes),
  );
  if (picked == null) {
    return null;
  }

  return minutesToTimeOfDay(timeOfDayToMinutes(picked));
}
