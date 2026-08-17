import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/application/use_cases/create_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/application/use_cases/update_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/exceptions/appointment_exceptions.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import 'package:lacos_app/features/appointments/domain/scheduling/scheduling_defaults.dart';
import 'package:lacos_app/features/appointments/domain/services/availability_engine.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_availability_calculator.dart';
import 'package:lacos_app/features/working_hours/domain/value_objects/working_day_availability.dart';

import '../../../../helpers/appointment_schedule_test_support.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

void main() {
  const engine = AvailabilityEngine();
  const calculator = AppointmentAvailabilityCalculator();

  group('SchedulingDefaults', () {
    test('A/B: opening 09:00 e closing 18:00', () {
      expect(SchedulingDefaults.openingMinutes, 9 * 60);
      expect(SchedulingDefaults.closingMinutes, 18 * 60);

      final day = DateTime(2026, 3, 10);
      expect(SchedulingDefaults.openingTimeOn(day), DateTime(2026, 3, 10, 9));
      expect(SchedulingDefaults.closingTimeOn(day), DateTime(2026, 3, 10, 18));
    });

    test('C: slot interval 15 min', () {
      expect(SchedulingDefaults.slotIntervalMinutes, 15);
    });

    test('G: time picker default equivale à abertura', () {
      final defaultTime = TimeOfDay(
        hour: SchedulingDefaults.openingMinutes ~/ 60,
        minute: SchedulingDefaults.openingMinutes % 60,
      );

      expect(defaultTime.hour, 9);
      expect(defaultTime.minute, 0);
    });

    test('L: domingo continua 09:00–18:00', () {
      final sunday = DateTime(2030, 6, 2);
      expect(sunday.weekday, DateTime.sunday);

      final slots = calculator.calculateAvailableStartTimes(
        day: sunday,
        durationMinutes: 60,
        dayAppointments: const [],
        professionalId: 'professional-1',
        dayAvailability: WorkingDayAvailability.fromDefaults(),
      );

      expect(slots.first, SchedulingDefaults.openingTimeOn(sunday));
      expect(slots.last, DateTime(2030, 6, 2, 17));
    });

    test('M: sábado continua 09:00–18:00', () {
      final saturday = DateTime(2030, 6, 1);
      expect(saturday.weekday, DateTime.saturday);

      final slots = calculator.calculateAvailableStartTimes(
        day: saturday,
        durationMinutes: 60,
        dayAppointments: const [],
        professionalId: 'professional-1',
        dayAvailability: WorkingDayAvailability.fromDefaults(),
      );

      expect(slots.first, SchedulingDefaults.openingTimeOn(saturday));
      expect(slots.last, DateTime(2030, 6, 1, 17));
    });
  });

  group('AvailabilityEngine com SchedulingDefaults', () {
    final day = DateTime(2025, 7, 6);
    late DateTime openingTime;
    late DateTime closingTime;

    setUp(() {
      openingTime = SchedulingDefaults.openingTimeOn(day);
      closingTime = SchedulingDefaults.closingTimeOn(day);
    });

    test('D: calculator usa defaults', () {
      final slots = calculator.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        dayAppointments: const [],
        professionalId: 'professional-1',
        dayAvailability: WorkingDayAvailability.fromDefaults(),
      );

      expect(slots.first, openingTime);
      expect(slots.last, DateTime(2025, 7, 6, 17));
      expect(slots.length, 33);
    });

    test('H/I: primeiro slot 09:00 e último start 17:00 para 60 min', () {
      final available = engine.calculateAvailableStartTimes(
        day: day,
        durationMinutes: 60,
        existingAppointments: const [],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(available.first, DateTime(2025, 7, 6, 9));
      expect(available.last, DateTime(2025, 7, 6, 17));
    });

    test('J: serviço pode terminar exatamente às 18:00', () {
      final isAvailable = engine.isIntervalAvailable(
        startAt: DateTime(2025, 7, 6, 17),
        endAt: DateTime(2025, 7, 6, 18),
        professionalId: 'professional-1',
        existingAppointments: const [],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(isAvailable, isTrue);
    });

    test('K: start 18:15 continua inválido', () {
      final isAvailable = engine.isIntervalAvailable(
        startAt: DateTime(2025, 7, 6, 18, 15),
        endAt: DateTime(2025, 7, 6, 19, 15),
        professionalId: 'professional-1',
        existingAppointments: const [],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(isAvailable, isFalse);
    });

    test('O: canceled continua ignorado', () {
      final isAvailable = engine.isIntervalAvailable(
        startAt: DateTime(2025, 7, 6, 9),
        endAt: DateTime(2025, 7, 6, 10),
        professionalId: 'professional-1',
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
            status: AppointmentStatus.canceled,
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(isAvailable, isTrue);
    });

    test('P: adjacente continua permitido', () {
      final isAvailable = engine.isIntervalAvailable(
        startAt: DateTime(2025, 7, 6, 10),
        endAt: DateTime(2025, 7, 6, 11),
        professionalId: 'professional-1',
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(isAvailable, isTrue);
    });

    test('N: conflito permanece por Professional', () {
      final isAvailable = engine.isIntervalAvailable(
        startAt: DateTime(2025, 7, 6, 9),
        endAt: DateTime(2025, 7, 6, 10),
        professionalId: 'professional-b',
        existingAppointments: [
          _appointment(
            start: DateTime(2025, 7, 6, 9),
            end: DateTime(2025, 7, 6, 10),
            professionalId: 'professional-a',
          ),
        ],
        openingTime: openingTime,
        closingTime: closingTime,
      );

      expect(isAvailable, isTrue);
    });
  });

  group('Use cases com SchedulingDefaults', () {
    late _FakeAppointmentRepository appointmentRepository;
    late _FakeAppointmentServiceRepository appointmentServiceRepository;
    late CreateAppointmentUseCase createUseCase;
    late UpdateAppointmentUseCase updateUseCase;

    setUp(() {
      appointmentRepository = _FakeAppointmentRepository();
      appointmentServiceRepository = _FakeAppointmentServiceRepository();
      final scheduleValidator = buildAppointmentScheduleValidator();
      createUseCase = CreateAppointmentUseCase(
        appointmentRepository: appointmentRepository,
        appointmentServiceRepository: appointmentServiceRepository,
        scheduleValidator: scheduleValidator,
      );
      updateUseCase = UpdateAppointmentUseCase(
        appointmentRepository: appointmentRepository,
        appointmentServiceRepository: appointmentServiceRepository,
        scheduleValidator: scheduleValidator,
      );
    });

    test('E: create rejeita horário antes da abertura default', () async {
      final day = DateTime.now().add(const Duration(days: 2));
      final startAt = DateTime(day.year, day.month, day.day, 8, 30);
      final endAt = startAt.add(const Duration(minutes: 60));

      await expectLater(
        createUseCase(
          clientId: 'client-1',
          professionalId: 'professional-1',
          services: [_service()],
          startAt: startAt,
          endAt: endAt,
          existingAppointments: const [],
        ),
        throwsA(isA<AppointmentUnavailableException>()),
      );

      expect(appointmentRepository.createCalls, 0);
    });

    test('F: update rejeita horário após o fechamento default', () async {
      final day = DateTime(2026, 9, 10);
      final startAt = DateTime(day.year, day.month, day.day, 17, 30);
      final endAt = DateTime(day.year, day.month, day.day, 18, 30);
      final existing = _appointment(
        id: 'appointment-1',
        start: DateTime(day.year, day.month, day.day, 10),
        end: DateTime(day.year, day.month, day.day, 11),
      );

      appointmentRepository.appointment = existing;
      appointmentRepository.dayAppointments = [existing];

      await expectLater(
        updateUseCase(
          UpdateAppointmentParams(
            appointmentId: existing.id,
            clientId: existing.clientId,
            professionalId: existing.professionalId,
            services: [_service()],
            startAt: startAt,
            endAt: endAt,
          ),
        ),
        throwsA(isA<AppointmentUnavailableException>()),
      );

      expect(appointmentRepository.updateCalls, 0);
    });

    test('R: create aceita horário dentro da janela default', () async {
      final day = DateTime.now().add(const Duration(days: 2));
      final startAt = DateTime(day.year, day.month, day.day, 10);
      final endAt = startAt.add(const Duration(minutes: 60));

      final result = await createUseCase(
        clientId: 'client-1',
        professionalId: 'professional-1',
        services: [_service()],
        startAt: startAt,
        endAt: endAt,
        existingAppointments: const [],
      );

      expect(result.appointment.id, isNotEmpty);
      expect(appointmentRepository.createCalls, 1);
      expect(appointmentRepository.findByDayCalls, 1);
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

Appointment _appointment({
  String id = 'appointment-1',
  required DateTime start,
  required DateTime end,
  AppointmentStatus status = AppointmentStatus.confirmed,
  String professionalId = 'professional-1',
}) {
  final now = DateTime(2025, 7, 6);

  return Appointment(
    id: id,
    salonId: 'salon-1',
    ownerId: 'owner-1',
    clientId: 'client-1',
    professionalId: professionalId,
    startAt: start,
    endAt: end,
    status: status,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  Appointment? appointment;
  List<Appointment> dayAppointments = const [];
  var findByDayCalls = 0;
  var createCalls = 0;
  var updateCalls = 0;

  @override
  Future<Appointment> create(Appointment appointment) async {
    createCalls++;
    return Appointment(
      id: 'appointment-created',
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
  Future<Appointment?> findNextByClientId(
    String clientId, {
    required DateTime now,
  }) async =>
      null;

  @override
  Future<List<Appointment>> findCanceledByClientId(String clientId) async =>
      const [];

  @override
  Future<Appointment> findById(String appointmentId) async {
    final value = appointment;
    if (value == null) {
      throw StateError('missing appointment');
    }
    return value;
  }

  @override
  Future<List<Appointment>> findByDay(DateTime day) async {
    findByDayCalls++;
    return dayAppointments;
  }

  @override
  Future<List<Appointment>> findByDateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  }) async =>
      const [];

  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async =>
      const {};

  @override
  Future<Appointment> update(Appointment appointment) async {
    updateCalls++;
    return appointment;
  }
}

class _FakeAppointmentServiceRepository
    implements AppointmentServiceRepository {
  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) async =>
      services;

  @override
  Future<void> deleteByAppointment(String appointmentId) async {}

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
