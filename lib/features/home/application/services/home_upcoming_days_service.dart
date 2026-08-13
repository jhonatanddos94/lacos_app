import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';

class HomeUpcomingDaysRange {
  const HomeUpcomingDaysRange({
    required this.startInclusive,
    required this.endExclusive,
  });

  final DateTime startInclusive;
  final DateTime endExclusive;
}

class HomeUpcomingDaysService {
  const HomeUpcomingDaysService._();

  static const horizonDays = 7;
  static const maxDisplayedDays = 3;

  static const _countableStatuses = {
    AppointmentStatus.pending,
    AppointmentStatus.confirmed,
  };

  static HomeUpcomingDaysRange resolveRange(DateTime today) {
    final normalizedToday = normalizeAppointmentDate(today);
    final startInclusive = normalizedToday.add(const Duration(days: 1));
    final endExclusive = normalizedToday.add(
      Duration(days: horizonDays + 1),
    );

    return HomeUpcomingDaysRange(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }

  static List<HomeUpcomingDay> buildFromAppointments({
    required DateTime today,
    required List<Appointment> appointments,
  }) {
    final range = resolveRange(today);
    final countsByDay = <AgendaDay, int>{};

    for (final appointment in appointments) {
      if (!_countableStatuses.contains(appointment.status)) {
        continue;
      }

      final day = AgendaDay.from(appointment.startAt);
      final dayStart = day.toDateTime();
      if (dayStart.isBefore(range.startInclusive) ||
          !dayStart.isBefore(range.endExclusive)) {
        continue;
      }

      countsByDay[day] = (countsByDay[day] ?? 0) + 1;
    }

    final sortedDays = countsByDay.keys.toList(growable: false)
      ..sort((a, b) => a.toDateTime().compareTo(b.toDateTime()));

    return sortedDays
        .take(maxDisplayedDays)
        .map(
          (day) => HomeUpcomingDay(
            day: day.toDateTime(),
            appointmentCount: countsByDay[day]!,
          ),
        )
        .toList(growable: false);
  }
}
