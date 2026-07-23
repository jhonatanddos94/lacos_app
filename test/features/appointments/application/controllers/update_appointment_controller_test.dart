import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/controllers/update_appointment_controller.dart';
import 'package:lacos_app/features/appointments/application/models/updated_appointment.dart';
import 'package:lacos_app/features/appointments/application/use_cases/update_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  group('UpdateAppointmentController', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeAppointmentServiceRepository appointmentServiceRepository;
    late UpdateAppointmentController controller;

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      appointmentServiceRepository = _FakeAppointmentServiceRepository();
      controller = UpdateAppointmentController(
        UpdateAppointmentUseCase(
          appointmentRepository: appointmentRepository,
          appointmentServiceRepository: appointmentServiceRepository,
          availabilityEngine: const AvailabilityEngine(),
        ),
      );
    });

    test('expõe erro específico quando sync de serviços falha', () async {
      appointmentRepository.appointment = _appointment();
      appointmentRepository.dayAppointments = [
        appointmentRepository.appointment!,
      ];
      appointmentServiceRepository.shouldFailCreateMany = true;

      final result = await controller.save(
        appointmentId: 'appointment-1',
        clientId: 'client-1',
        professionalId: 'professional-1',
        services: [_service()],
        startAt: DateTime(2026, 8, 21, 10),
        endAt: DateTime(2026, 8, 21, 11),
      );

      expect(result, isNull);
      expect(controller.state, isA<AsyncError<UpdatedAppointment?>>());
      expect(
        controller.state.error,
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          AppStrings.appointmentServicesUpdateError,
        ),
      );
    });
  });

  group('resolveUpdateAppointmentErrorMessage', () {
    test(
      'mapeia AppointmentServicesUpdateException para mensagem específica',
      () {
        expect(
          resolveUpdateAppointmentErrorMessage(
            const AppointmentServicesUpdateException(),
          ),
          AppStrings.appointmentServicesUpdateError,
        );
      },
    );
  });
}

Service _service() {
  final now = DateTime(2026, 1, 1);

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

Appointment _appointment() {
  final startAt = DateTime(2026, 8, 21, 10);
  return Appointment(
    id: 'appointment-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: 'professional-1',
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 1)),
    status: AppointmentStatus.pending,
    isActive: true,
    createdAt: startAt,
    updatedAt: startAt,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;
  List<Appointment> dayAppointments = const [];

  @override
  Future<Appointment> findById(String appointmentId) async => appointment!;

  @override
  Future<List<Appointment>> findByDay(DateTime day) async => dayAppointments;

  @override
  Future<Appointment> update(Appointment appointment) async {
    this.appointment = appointment;
    return appointment;
  }

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async => const {};

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
}

class _FakeAppointmentServiceRepository
    implements AppointmentServiceRepository {
  var shouldFailCreateMany = false;

  @override
  Future<void> deleteByAppointment(String appointmentId) async {}

  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) async {
    if (shouldFailCreateMany) {
      throw StateError('createMany failed');
    }
    return services;
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
