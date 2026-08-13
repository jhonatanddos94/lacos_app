import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/home/application/loaders/home_upcoming_days_loader.dart';

void main() {
  final today = DateTime(2026, 8, 13);

  Appointment appointment(DateTime startAt) {
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

  test('query chamada UMA vez', () async {
    final repository = _RecordingAppointmentRepository(
      appointments: [
        appointment(DateTime(2026, 8, 14, 10)),
        appointment(DateTime(2026, 8, 15, 10)),
      ],
    );
    final loader = HomeUpcomingDaysLoader(appointmentRepository: repository);

    await loader.load(today: today);

    expect(repository.findByDateRangeCalls, 1);
  });

  test('range correto com startInclusive e endExclusive', () async {
    final repository = _RecordingAppointmentRepository(appointments: const []);
    final loader = HomeUpcomingDaysLoader(appointmentRepository: repository);

    await loader.load(today: today);

    expect(repository.lastStartInclusive, DateTime(2026, 8, 14));
    expect(repository.lastEndExclusive, DateTime(2026, 8, 21));
  });

  test('status pending e confirmed', () async {
    final repository = _RecordingAppointmentRepository(appointments: const []);
    final loader = HomeUpcomingDaysLoader(appointmentRepository: repository);

    await loader.load(today: today);

    expect(
      repository.lastStatuses,
      containsAll([
        AppointmentStatus.pending,
        AppointmentStatus.confirmed,
      ]),
    );
  });
}

class _RecordingAppointmentRepository implements AppointmentRepository {
  _RecordingAppointmentRepository({required this.appointments});

  final List<Appointment> appointments;
  var findByDateRangeCalls = 0;
  DateTime? lastStartInclusive;
  DateTime? lastEndExclusive;
  Iterable<AppointmentStatus>? lastStatuses;

  @override
  Future<List<Appointment>> findByDateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  }) async {
    findByDateRangeCalls++;
    lastStartInclusive = startInclusive;
    lastEndExclusive = endExclusive;
    lastStatuses = statuses;
    return appointments;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
