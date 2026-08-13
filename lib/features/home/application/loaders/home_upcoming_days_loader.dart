import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/services/home_upcoming_days_service.dart';

class HomeUpcomingDaysLoader {
  const HomeUpcomingDaysLoader({
    required AppointmentRepository appointmentRepository,
  }) : _appointmentRepository = appointmentRepository;

  final AppointmentRepository _appointmentRepository;

  Future<List<HomeUpcomingDay>> load({required DateTime today}) async {
    final range = HomeUpcomingDaysService.resolveRange(today);
    final appointments = await _appointmentRepository.findByDateRange(
      startInclusive: range.startInclusive,
      endExclusive: range.endExclusive,
      statuses: const [
        AppointmentStatus.pending,
        AppointmentStatus.confirmed,
      ],
    );

    return HomeUpcomingDaysService.buildFromAppointments(
      today: today,
      appointments: appointments,
    );
  }
}
