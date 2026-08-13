import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/mappers/appointment_preparation_mapper.dart';

void main() {
  test('fromDisplay monta header sem memórias e sem I/O', () {
    final data = AppointmentPreparationMapper.fromDisplay(
      AgendaAppointmentDisplay(
        appointmentId: 'appointment-1',
        clientId: 'client-1',
        clientName: 'Maria Silva',
        clientPhotoUrl: 'https://example.com/photo.jpg',
        servicesSummary: 'Corte',
        startAt: DateTime(2026, 8, 13, 10),
        endAt: DateTime(2026, 8, 13, 11),
        status: AppointmentStatus.confirmed,
      ),
    );

    expect(data.clientName, 'Maria Silva');
    expect(data.clientPhotoUrl, 'https://example.com/photo.jpg');
    expect(data.servicesSummary, 'Corte');
    expect(data.scheduleTimeLabel, '10:00 – 11:00');
    expect(data.memories, isEmpty);
  });
}
