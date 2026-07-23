import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/application/helpers/appointment_preparation_memory_sorter.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_preparation_data.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';

class AppointmentPreparationMapper {
  const AppointmentPreparationMapper._();

  static AppointmentPreparationData from({
    required AgendaAppointmentDisplay appointment,
    required List<ClientMemory> memories,
  }) {
    return AppointmentPreparationData(
      appointmentId: appointment.appointmentId,
      clientId: appointment.clientId,
      clientName: appointment.clientName,
      clientPhotoUrl: appointment.clientPhotoUrl,
      servicesSummary: appointment.servicesSummary,
      scheduleTimeLabel: _scheduleTimeLabel(
        startAt: appointment.startAt,
        endAt: appointment.endAt,
      ),
      memories: AppointmentPreparationMemorySorter.selectTop(
        memories: memories,
      ),
    );
  }

  static String _scheduleTimeLabel({
    required DateTime startAt,
    required DateTime endAt,
  }) {
    return '${formatAppointmentClockTime(startAt)} – '
        '${formatAppointmentClockTime(endAt)}';
  }
}
