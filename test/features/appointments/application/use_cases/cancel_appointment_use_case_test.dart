import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/use_cases/cancel_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';

void main() {
  group('CancelAppointmentUseCase', () {
    late _FakeAppointmentRepository repository;
    late CancelAppointmentUseCase useCase;

    setUp(() {
      repository = _FakeAppointmentRepository();
      useCase = CancelAppointmentUseCase(appointmentRepository: repository);
    });

    test('cancela agendamento pendente', () async {
      repository.appointment = _appointment(status: AppointmentStatus.pending);

      final result = await useCase('appointment-1');

      expect(result.status, AppointmentStatus.canceled);
      expect(result.isActive, isTrue);
      expect(repository.cancelCalls, 1);
    });

    test('bloqueia cancelamento de agendamento concluído', () {
      repository.appointment = _appointment(status: AppointmentStatus.completed);

      expect(
        () => useCase('appointment-1'),
        throwsA(isA<AppointmentCannotCancelCompletedException>()),
      );
      expect(repository.cancelCalls, 0);
    });

    test('retorna agendamento já cancelado sem chamar cancel novamente', () async {
      repository.appointment = _appointment(status: AppointmentStatus.canceled);

      final result = await useCase('appointment-1');

      expect(result.status, AppointmentStatus.canceled);
      expect(repository.cancelCalls, 0);
    });
  });
}

Appointment _appointment({
  AppointmentStatus status = AppointmentStatus.pending,
}) {
  final now = DateTime(2025, 7, 6, 10);

  return Appointment(
    id: 'appointment-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: now,
    endAt: now.add(const Duration(hours: 1)),
    status: status,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;
  var cancelCalls = 0;

  @override
  Future<Appointment> cancel(String appointmentId) async {
    cancelCalls++;
    return _appointment(status: AppointmentStatus.canceled);
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
  Future<Appointment> findById(String appointmentId) async {
    final current = appointment;
    if (current == null) {
      throw StateError('Agendamento não encontrado.');
    }
    return current;
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}
