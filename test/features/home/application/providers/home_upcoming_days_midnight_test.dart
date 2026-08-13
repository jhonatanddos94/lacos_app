import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  testWidgets('meia-noite recalcula o range de homeUpcomingDaysProvider', (
    tester,
  ) async {
    final clock = FakeAppClock(DateTime(2026, 8, 13, 23, 59));
    final repository = _RecordingAppointmentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(clock),
          appointmentRepositoryProvider.overrideWithValue(repository),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(homeUpcomingDaysProvider);
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.lastStartInclusive, DateTime(2026, 8, 14));
    expect(repository.lastEndExclusive, DateTime(2026, 8, 21));

    clock.setNow(DateTime(2026, 8, 14));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    expect(
      container.read(calendarTodayProvider),
      AgendaDay.from(DateTime(2026, 8, 14)),
    );
    expect(repository.findByDateRangeCalls, 2);
    expect(repository.lastStartInclusive, DateTime(2026, 8, 15));
    expect(repository.lastEndExclusive, DateTime(2026, 8, 22));
  });
}

class _RecordingAppointmentRepository implements AppointmentRepository {
  var findByDateRangeCalls = 0;
  DateTime? lastStartInclusive;
  DateTime? lastEndExclusive;

  @override
  Future<List<Appointment>> findByDateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
    Iterable<AppointmentStatus>? statuses,
  }) async {
    findByDateRangeCalls++;
    lastStartInclusive = startInclusive;
    lastEndExclusive = endExclusive;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
