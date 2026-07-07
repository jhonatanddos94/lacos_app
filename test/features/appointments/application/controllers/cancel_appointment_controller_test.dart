import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/controllers/cancel_appointment_controller.dart';
import 'package:lacos_app/features/appointments/application/models/cancel_appointment_params.dart';
import 'package:lacos_app/features/appointments/application/models/cancel_appointment_state.dart';
import 'package:lacos_app/features/appointments/application/use_cases/cancel_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';

void main() {
  group('CancelAppointmentController', () {
    late _FakeAppointmentRepository repository;
    late CancelAppointmentUseCase useCase;
    late CancelAppointmentController controller;

    setUp(() {
      repository = _FakeAppointmentRepository();
      useCase = CancelAppointmentUseCase(appointmentRepository: repository);
      controller = CancelAppointmentController(useCase);
    });

    test('erro se canceledBy não foi selecionado', () async {
      final result = await controller.cancel('appointment-1');

      expect(result, isNull);
      expect(
        controller.state.errorMessage,
        AppStrings.appointmentCancelWhoCanceledRequired,
      );
      expect(repository.cancelCalls, 0);
    });

    test('sucesso ao cancelar', () async {
      repository.appointment = _appointment();
      controller
        ..setCanceledBy(AppointmentCanceledBy.client)
        ..setCancellationReason('Cliente desistiu');

      final result = await controller.cancel('appointment-1');

      expect(result, isNotNull);
      expect(result!.status, AppointmentStatus.canceled);
      expect(controller.state.success, isTrue);
      expect(repository.lastCanceledBy, AppointmentCanceledBy.client);
      expect(repository.lastCancellationReason, 'Cliente desistiu');
    });

    test('loading impede duplo clique', () async {
      repository.appointment = _appointment();
      repository.cancelDelay = Future<void>.delayed(const Duration(milliseconds: 50));
      controller.setCanceledBy(AppointmentCanceledBy.salon);

      final first = controller.cancel('appointment-1');
      final second = controller.cancel('appointment-1');

      expect(await second, isNull);
      await first;
      expect(repository.cancelCalls, 1);
    });

    test('reset limpa estado', () {
      controller
        ..setCanceledBy(AppointmentCanceledBy.client)
        ..setCancellationReason('Motivo')
        ..reset();

      expect(controller.state, const CancelAppointmentState());
    });

    test('mapeia AppointmentCannotCancelCompletedException', () async {
      repository.appointment = _appointment(status: AppointmentStatus.completed);
      controller.setCanceledBy(AppointmentCanceledBy.client);

      final result = await controller.cancel('appointment-1');

      expect(result, isNull);
      expect(
        controller.state.errorMessage,
        AppStrings.appointmentCannotCancelCompleted,
      );
    });
  });
}

Appointment _appointment({
  AppointmentStatus status = AppointmentStatus.pending,
}) {
  final now = DateTime(2026, 7, 7, 10);

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
  AppointmentCanceledBy? lastCanceledBy;
  String? lastCancellationReason;
  Future<void>? cancelDelay;

  @override
  Future<Appointment> cancel({
    required String appointmentId,
    required AppointmentCanceledBy canceledBy,
    String? cancellationReason,
  }) async {
    cancelCalls++;
    lastCanceledBy = canceledBy;
    lastCancellationReason = cancellationReason;
    await cancelDelay;
    return _appointment(status: AppointmentStatus.canceled);
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
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) {
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
