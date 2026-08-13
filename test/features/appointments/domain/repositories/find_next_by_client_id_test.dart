import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';

void main() {
  group('findNextByClientId query contract', () {
    late _InMemoryAppointmentRepository repository;
    final now = DateTime(2026, 7, 14, 15);

    setUp(() {
      repository = _InMemoryAppointmentRepository(salonId: 'salon-1');
    });

    Appointment build({
      required String id,
      required String clientId,
      required DateTime startAt,
      required DateTime endAt,
      AppointmentStatus status = AppointmentStatus.pending,
      bool isActive = true,
      String salonId = 'salon-1',
    }) {
      return Appointment(
        id: id,
        salonId: salonId,
        ownerId: 'owner-1',
        clientId: clientId,
        professionalId: 'professional-1',
        startAt: startAt,
        endAt: endAt,
        status: status,
        isActive: isActive,
        createdAt: startAt,
        updatedAt: startAt,
      );
    }

    test('filtra por cliente e retorna o mais próximo', () async {
      repository.appointments.addAll([
        build(
          id: 'later',
          clientId: 'client-1',
          startAt: now.add(const Duration(hours: 3)),
          endAt: now.add(const Duration(hours: 4)),
        ),
        build(
          id: 'next',
          clientId: 'client-1',
          startAt: now.add(const Duration(hours: 1)),
          endAt: now.add(const Duration(hours: 2)),
        ),
        build(
          id: 'other-client',
          clientId: 'client-2',
          startAt: now.add(const Duration(minutes: 30)),
          endAt: now.add(const Duration(hours: 1, minutes: 30)),
        ),
      ]);

      final result = await repository.findNextByClientId('client-1', now: now);

      expect(result?.id, 'next');
    });

    test('ignora cancelados, concluídos, inativos e expirados', () async {
      repository.appointments.addAll([
        build(
          id: 'canceled',
          clientId: 'client-1',
          startAt: now.add(const Duration(hours: 1)),
          endAt: now.add(const Duration(hours: 2)),
          status: AppointmentStatus.canceled,
        ),
        build(
          id: 'completed',
          clientId: 'client-1',
          startAt: now.add(const Duration(hours: 1)),
          endAt: now.add(const Duration(hours: 2)),
          status: AppointmentStatus.completed,
        ),
        build(
          id: 'inactive',
          clientId: 'client-1',
          startAt: now.add(const Duration(hours: 1)),
          endAt: now.add(const Duration(hours: 2)),
          isActive: false,
        ),
        build(
          id: 'expired',
          clientId: 'client-1',
          startAt: now.subtract(const Duration(hours: 2)),
          endAt: now.subtract(const Duration(minutes: 1)),
        ),
      ]);

      final result = await repository.findNextByClientId('client-1', now: now);

      expect(result, isNull);
    });

    test('inclui pending, confirmed e atendimento em andamento', () async {
      repository.appointments.addAll([
        build(
          id: 'pending',
          clientId: 'client-1',
          startAt: now.add(const Duration(hours: 2)),
          endAt: now.add(const Duration(hours: 3)),
          status: AppointmentStatus.pending,
        ),
        build(
          id: 'confirmed',
          clientId: 'client-1',
          startAt: now.add(const Duration(hours: 1)),
          endAt: now.add(const Duration(hours: 2)),
          status: AppointmentStatus.confirmed,
        ),
        build(
          id: 'current',
          clientId: 'client-1',
          startAt: now.subtract(const Duration(minutes: 20)),
          endAt: now.add(const Duration(minutes: 40)),
        ),
      ]);

      final result = await repository.findNextByClientId('client-1', now: now);

      expect(result?.id, 'current');
    });

    test('retorna null quando clientId está vazio', () async {
      final result = await repository.findNextByClientId('', now: now);
      expect(result, isNull);
    });

    test('propaga erro do repositório', () async {
      repository.shouldFail = true;

      expect(
        repository.findNextByClientId('client-1', now: now),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

class _InMemoryAppointmentRepository implements AppointmentRepository {
  _InMemoryAppointmentRepository({required this.salonId});

  final String salonId;
  final List<Appointment> appointments = [];
  var shouldFail = false;

  @override
  Future<Appointment?> findNextByClientId(
    String clientId, {
    required DateTime now,
  }) async {
    if (shouldFail) {
      throw const FormatException('Falha simulada');
    }

    if (clientId.trim().isEmpty) {
      return null;
    }

    final eligible =
        appointments
            .where(
              (appointment) =>
                  appointment.salonId == salonId &&
                  appointment.clientId == clientId &&
                  appointment.isActive &&
                  appointment.status != AppointmentStatus.canceled &&
                  appointment.status != AppointmentStatus.completed &&
                  appointment.endAt.isAfter(now),
            )
            .toList(growable: false)
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (eligible.isEmpty) {
      return null;
    }

    return eligible.first;
  }

  @override
  Future<List<Appointment>> findCanceledByClientId(String clientId) async {
    return const [];
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
  Future<List<Appointment>> findByDay(DateTime day) async => const [];
  @override
  Future<List<Appointment>> findByDateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  }) async => const [];


  @override
  Future<Set<DateTime>> findActiveAppointmentDaysInRange({
    required DateTime start,
    required DateTime end,
  }) async => const {};

  @override
  Future<Appointment> findById(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<Appointment> update(Appointment appointment) {
    throw UnimplementedError();
  }
}
