import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_month_grid.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';

class AgendaCalendarAppointmentDaysLoader {
  const AgendaCalendarAppointmentDaysLoader({
    required AppointmentRepository appointmentRepository,
  }) : _appointmentRepository = appointmentRepository;

  final AppointmentRepository _appointmentRepository;

  Future<Set<DateTime>> loadForMonth({
    required int year,
    required int month,
  }) async {
    final grid = AgendaCalendarMonthGrid(year: year, month: month);
    final range = grid.visibleDateRange();

    return _appointmentRepository.findActiveAppointmentDaysInRange(
      start: range.start,
      end: range.end,
    );
  }
}
