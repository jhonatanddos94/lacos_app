import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/application/loaders/agenda_calendar_appointment_days_loader.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';

void main() {
  group('AgendaCalendarAppointmentDaysLoader', () {
    test('consulta o intervalo visível da grade mensal', () async {
      final repository = _FakeAppointmentRepository();
      final loader = AgendaCalendarAppointmentDaysLoader(
        appointmentRepository: repository,
      );

      final days = await loader.loadForMonth(year: 2026, month: 7);

      expect(repository.lastStart, DateTime(2026, 6, 29));
      expect(repository.lastEnd, DateTime(2026, 8, 9));
      expect(days, {DateTime(2026, 7, 15)});
    });
  });
}

class _FakeAppointmentRepository implements AppointmentRepository {
  DateTime? lastStart;
  DateTime? lastEnd;

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    lastStart = start;
    lastEnd = end;
    return {DateTime(2026, 7, 15)};
  }

  @override
  Future<Appointment> cancel({
    required String appointmentId,
    required AppointmentCanceledBy canceledBy,
    String? cancellationReason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> complete(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> create(Appointment appointment) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Appointment>> findByDay(DateTime day) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> findById(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}
