import 'package:lacos_app/features/appointments/domain/scheduling/scheduling_defaults.dart';

class WorkingDayAvailability {
  const WorkingDayAvailability({
    required this.isWorking,
    required this.startMinutes,
    required this.endMinutes,
  });

  final bool isWorking;
  final int startMinutes;
  final int endMinutes;

  factory WorkingDayAvailability.fromDefaults() {
    return const WorkingDayAvailability(
      isWorking: true,
      startMinutes: SchedulingDefaults.openingMinutes,
      endMinutes: SchedulingDefaults.closingMinutes,
    );
  }

  factory WorkingDayAvailability.closed() {
    return const WorkingDayAvailability(
      isWorking: false,
      startMinutes: SchedulingDefaults.openingMinutes,
      endMinutes: SchedulingDefaults.closingMinutes,
    );
  }

  factory WorkingDayAvailability.working({
    required int startMinutes,
    required int endMinutes,
  }) {
    return WorkingDayAvailability(
      isWorking: true,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
  }
}
