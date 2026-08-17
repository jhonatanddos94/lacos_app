import 'package:lacos_app/features/appointments/domain/scheduling/scheduling_defaults.dart';
import 'package:lacos_app/features/working_hours/domain/entities/professional_working_hours.dart';

class WorkingHoursDayDraft {
  const WorkingHoursDayDraft({
    required this.weekday,
    required this.isWorking,
    required this.startMinutes,
    required this.endMinutes,
    this.id,
  });

  final String? id;
  final int weekday;
  final bool isWorking;
  final int startMinutes;
  final int endMinutes;

  WorkingHoursDayDraft copyWith({
    String? id,
    int? weekday,
    bool? isWorking,
    int? startMinutes,
    int? endMinutes,
  }) {
    return WorkingHoursDayDraft(
      id: id ?? this.id,
      weekday: weekday ?? this.weekday,
      isWorking: isWorking ?? this.isWorking,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }
}

abstract final class WorkingHoursWeekFactory {
  static List<WorkingHoursDayDraft> defaultWeek() {
    return [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        WorkingHoursDayDraft(
          weekday: weekday,
          isWorking: true,
          startMinutes: SchedulingDefaults.openingMinutes,
          endMinutes: SchedulingDefaults.closingMinutes,
        ),
    ];
  }

  static List<WorkingHoursDayDraft> fromPersisted(
    List<ProfessionalWorkingHours> week,
  ) {
    if (week.isEmpty) {
      return defaultWeek();
    }

    final byWeekday = {for (final entry in week) entry.weekday: entry};

    return [
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        _fromEntry(byWeekday[weekday], weekday),
    ];
  }

  static WorkingHoursDayDraft _fromEntry(
    ProfessionalWorkingHours? entry,
    int weekday,
  ) {
    if (entry == null) {
      return WorkingHoursDayDraft(
        weekday: weekday,
        isWorking: true,
        startMinutes: SchedulingDefaults.openingMinutes,
        endMinutes: SchedulingDefaults.closingMinutes,
      );
    }

    return WorkingHoursDayDraft(
      id: entry.id,
      weekday: entry.weekday,
      isWorking: entry.isWorking,
      startMinutes: entry.startMinutes,
      endMinutes: entry.endMinutes,
    );
  }

  static List<ProfessionalWorkingHours> toDomain({
    required String salonId,
    required String professionalId,
    required List<WorkingHoursDayDraft> drafts,
    required DateTime now,
  }) {
    return drafts
        .map(
          (draft) => ProfessionalWorkingHours(
            id: draft.id ?? '',
            salonId: salonId,
            professionalId: professionalId,
            weekday: draft.weekday,
            isWorking: draft.isWorking,
            startMinutes: draft.startMinutes,
            endMinutes: draft.endMinutes,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList(growable: false);
  }
}
