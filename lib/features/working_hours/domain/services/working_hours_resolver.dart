import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';
import 'package:lacos_app/features/working_hours/domain/value_objects/working_day_availability.dart';

/// Resolve a disponibilidade operacional da Professional em um dia.
///
/// Sem configuração persistida, retorna [SchedulingDefaults] via
/// [WorkingDayAvailability.fromDefaults].
abstract final class WorkingHoursResolver {
  static WorkingDayAvailability resolve({
    required DateTime day,
    required List<ProfessionalWorkingHours> configuredWeek,
  }) {
    if (configuredWeek.isEmpty) {
      return WorkingDayAvailability.fromDefaults();
    }

    final weekday = day.weekday;
    ProfessionalWorkingHours? entry;
    for (final candidate in configuredWeek) {
      if (candidate.weekday == weekday) {
        entry = candidate;
        break;
      }
    }

    if (entry == null) {
      return WorkingDayAvailability.fromDefaults();
    }

    if (!entry.isWorking) {
      return WorkingDayAvailability.closed();
    }

    return WorkingDayAvailability.working(
      startMinutes: entry.startMinutes,
      endMinutes: entry.endMinutes,
    );
  }
}
