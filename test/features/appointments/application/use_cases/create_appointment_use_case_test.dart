import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/use_cases/create_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  group('CreateAppointmentUseCase', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeAppointmentServiceRepository appointmentServiceRepository;
    late CreateAppointmentUseCase useCase;

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      appointmentServiceRepository = _FakeAppointmentServiceRepository();
      useCase = CreateAppointmentUseCase(
        appointmentRepository: appointmentRepository,
        appointmentServiceRepository: appointmentServiceRepository,
        availabilityEngine: const AvailabilityEngine(),
      );
    });

    test('bloqueia agendamento com startAt no passado', () {
      final now = DateTime.now();
      final pastStart = now.subtract(const Duration(minutes: 30));
      final pastEnd = pastStart.add(const Duration(minutes: 60));

      expect(
        () => useCase(
          clientId: 'client-1',
          professionalId: 'professional-1',
          services: [_service()],
          startAt: pastStart,
          endAt: pastEnd,
          existingAppointments: const [],
        ),
        throwsA(
          isA<AppointmentValidationException>().having(
            (error) => error.code,
            'code',
            AppointmentValidationCode.startAtInPast,
          ),
        ),
      );

      expect(appointmentRepository.findByDayCalls, 0);
      expect(appointmentRepository.createCalls, 0);
    });

    test('permite agendamento em data futura', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final startAt = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        10,
      );
      final endAt = startAt.add(const Duration(minutes: 60));

      final result = await useCase(
        clientId: 'client-1',
        professionalId: 'professional-1',
        services: [_service()],
        startAt: startAt,
        endAt: endAt,
        existingAppointments: const [],
      );

      expect(result.appointment.id, isNotEmpty);
      expect(appointmentRepository.createCalls, 1);
    });
  });
}

Service _service() {
  final now = DateTime.now();

  return Service(
    id: 'service-1',
    name: 'Corte',
    durationMinutes: 60,
    price: 80,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  var findByDayCalls = 0;
  var createCalls = 0;

  @override
  Future<Appointment> create(Appointment appointment) async {
    createCalls++;
    return Appointment(
      id: 'appointment-1',
      salonId: appointment.salonId,
      ownerId: appointment.ownerId,
      clientId: appointment.clientId,
      professionalId: appointment.professionalId,
      startAt: appointment.startAt,
      endAt: appointment.endAt,
      status: appointment.status,
      notes: appointment.notes,
      isActive: appointment.isActive,
      createdAt: appointment.createdAt,
      updatedAt: appointment.updatedAt,
    );
  }

  @override
  Future<Appointment> cancel(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> findById(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Appointment>> findByDay(DateTime day) async {
    findByDayCalls++;
    return const [];
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}

class _FakeAppointmentServiceRepository
    implements AppointmentServiceRepository {
  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) async {
    return services;
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<List<AppointmentService>> findByAppointment(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) {
    throw UnimplementedError();
  }
}
