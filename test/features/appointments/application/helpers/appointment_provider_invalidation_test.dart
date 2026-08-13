import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_calendar_view.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/appointments/application/helpers/appointment_provider_invalidation.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details_query.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_details_providers.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/clients/application/providers/client_next_appointment_providers.dart';
import 'package:lacos_app/features/clients/application/providers/client_service_history_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/service_records/application/providers/service_record_providers.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/service_records/domain/repositories/service_record_repository.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/home/application/models/home_upcoming_day.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';

void main() {
  testWidgets('invalidateAppointmentAfterUpdate invalida detalhes e agenda', (
    tester,
  ) async {
    var loaderCalls = 0;
    late WidgetRef widgetRef;

    AppointmentDetails buildDetails(AppointmentDetailsQuery query) {
      final day = query.day;
      return AppointmentDetails(
        appointment: Appointment(
          id: query.appointmentId,
          salonId: 'salon-1',
          ownerId: 'owner-1',
          clientId: 'client-1',
          professionalId: 'professional-1',
          startAt: day,
          endAt: day.add(const Duration(hours: 1)),
          status: AppointmentStatus.pending,
          isActive: true,
          createdAt: day,
          updatedAt: day,
        ),
        client: Client(
          id: 'client-1',
          name: 'Ana',
          phone: '11999999999',
          isActive: true,
          createdAt: day,
          updatedAt: day,
        ),
        professional: Professional(
          id: 'professional-1',
          name: 'Maria',
          isActive: true,
          createdAt: day,
          updatedAt: day,
        ),
        services: [
          Service(
            id: 'service-1',
            name: 'Corte',
            durationMinutes: 60,
            price: 80,
            isActive: true,
            createdAt: day,
            updatedAt: day,
          ),
        ],
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentDetailsProvider.overrideWith((ref, query) async {
            loaderCalls++;
            return buildDetails(query);
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    final updatedDay = DateTime(2026, 8, 22, 10);
    final originalDay = DateTime(2026, 8, 21, 10);
    const appointmentId = 'appointment-1';
    final updatedAgendaDay = AgendaDay.from(updatedDay);
    final originalAgendaDay = AgendaDay.from(originalDay);

    final updatedQuery = AppointmentDetailsQuery(
      appointmentId: appointmentId,
      day: updatedDay,
    );
    final originalQuery = AppointmentDetailsQuery(
      appointmentId: appointmentId,
      day: originalDay,
    );

    await tester.runAsync(() async {
      await widgetRef.read(appointmentDetailsProvider(updatedQuery).future);
      await widgetRef.read(appointmentDetailsProvider(originalQuery).future);
      widgetRef.read(agendaAppointmentsDisplayProvider(updatedAgendaDay));
      widgetRef.read(agendaAppointmentsDisplayProvider(originalAgendaDay));
    });

    expect(loaderCalls, 2);

    invalidateAppointmentAfterUpdate(
      widgetRef,
      appointmentId: appointmentId,
      updatedDay: updatedDay,
      originalDay: originalDay,
    );

    await tester.runAsync(() async {
      await widgetRef.read(appointmentDetailsProvider(updatedQuery).future);
      await widgetRef.read(appointmentDetailsProvider(originalQuery).future);
    });

    expect(loaderCalls, 4);
  });

  testWidgets('invalidateAppointmentAfterCompletion invalida histórico', (
    tester,
  ) async {
    var serviceRecordByAppointmentCalls = 0;
    var serviceRecordsByClientCalls = 0;
    var clientServiceHistoryCalls = 0;
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceRecordRepositoryProvider.overrideWithValue(
            _FakeServiceRecordRepository(),
          ),
          serviceRecordByAppointmentProvider.overrideWith((ref, appointmentId) {
            serviceRecordByAppointmentCalls++;
            return Future.value(null);
          }),
          serviceRecordsByClientProvider.overrideWith((ref, clientId) {
            serviceRecordsByClientCalls++;
            return Future.value(const []);
          }),
          clientServiceHistoryProvider.overrideWith((ref, clientId) {
            clientServiceHistoryCalls++;
            return Future.value(const []);
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    const appointmentId = 'appointment-1';
    const clientId = 'client-1';
    final day = DateTime(2026, 8, 22, 10);

    await tester.runAsync(() async {
      await widgetRef.read(
        serviceRecordByAppointmentProvider(appointmentId).future,
      );
      await widgetRef.read(serviceRecordsByClientProvider(clientId).future);
      await widgetRef.read(clientServiceHistoryProvider(clientId).future);
    });

    expect(serviceRecordByAppointmentCalls, 1);
    expect(serviceRecordsByClientCalls, 1);
    expect(clientServiceHistoryCalls, 1);

    invalidateAppointmentAfterCompletion(
      widgetRef,
      appointmentId: appointmentId,
      clientId: clientId,
      day: day,
    );

    await tester.runAsync(() async {
      await widgetRef.read(
        serviceRecordByAppointmentProvider(appointmentId).future,
      );
      await widgetRef.read(serviceRecordsByClientProvider(clientId).future);
      await widgetRef.read(clientServiceHistoryProvider(clientId).future);
    });

    expect(serviceRecordByAppointmentCalls, 2);
    expect(serviceRecordsByClientCalls, 2);
    expect(clientServiceHistoryCalls, 2);
  });

  testWidgets('invalidateAppointmentAfterCancellation invalida histórico', (
    tester,
  ) async {
    var clientServiceHistoryCalls = 0;
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientServiceHistoryProvider.overrideWith((ref, clientId) {
            clientServiceHistoryCalls++;
            return Future.value(const []);
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    const appointmentId = 'appointment-1';
    const clientId = 'client-1';
    final day = DateTime(2026, 8, 22, 10);

    await tester.runAsync(() async {
      await widgetRef.read(clientServiceHistoryProvider(clientId).future);
    });
    expect(clientServiceHistoryCalls, 1);

    invalidateAppointmentAfterCancellation(
      widgetRef,
      appointmentId: appointmentId,
      clientId: clientId,
      day: day,
    );

    await tester.runAsync(() async {
      await widgetRef.read(clientServiceHistoryProvider(clientId).future);
    });
    expect(clientServiceHistoryCalls, 2);
  });

  testWidgets('invalidateAppointmentAfterCreate invalida próximo atendimento', (
    tester,
  ) async {
    var clientNextCalls = 0;
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientNextAppointmentProvider('client-1').overrideWith((ref) async {
            clientNextCalls++;
            return null;
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await widgetRef.read(clientNextAppointmentProvider('client-1').future);
    });

    expect(clientNextCalls, 1);

    invalidateAppointmentAfterCreate(
      widgetRef,
      clientId: 'client-1',
      day: DateTime(2026, 8, 22, 10),
    );

    await tester.runAsync(() async {
      await widgetRef.read(clientNextAppointmentProvider('client-1').future);
    });

    expect(clientNextCalls, 2);
  });

  testWidgets(
    'invalidateAppointmentAfterUpdate invalida clientes antigo e novo',
    (tester) async {
      final invalidatedClients = <String>[];
      late WidgetRef widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientNextAppointmentProvider('client-1').overrideWith((ref) async {
              invalidatedClients.add('client-1');
              return null;
            }),
            clientNextAppointmentProvider('client-2').overrideWith((ref) async {
              invalidatedClients.add('client-2');
              return null;
            }),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                widgetRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await widgetRef.read(clientNextAppointmentProvider('client-1').future);
        await widgetRef.read(clientNextAppointmentProvider('client-2').future);
      });

      invalidatedClients.clear();

      invalidateAppointmentAfterUpdate(
        widgetRef,
        appointmentId: 'appointment-1',
        updatedDay: DateTime(2026, 8, 22, 10),
        originalClientId: 'client-1',
        updatedClientId: 'client-2',
      );

      await tester.runAsync(() async {
        await widgetRef.read(clientNextAppointmentProvider('client-1').future);
        await widgetRef.read(clientNextAppointmentProvider('client-2').future);
      });

      expect(invalidatedClients, containsAll(['client-1', 'client-2']));
    },
  );

  testWidgets(
    'invalidateAppointmentAfterCreate invalida homeUpcomingDays e calendário',
    (tester) async {
      var upcomingCalls = 0;
      var calendarCalls = 0;
      late WidgetRef widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeUpcomingDaysProvider.overrideWith((ref) async {
              upcomingCalls++;
              return [
                HomeUpcomingDay(
                  day: DateTime(2026, 8, 14),
                  appointmentCount: 1,
                ),
              ];
            }),
            agendaCalendarAppointmentDaysProvider.overrideWith(
              (ref, view) async {
                calendarCalls++;
                return {DateTime(2026, 8, 14)};
              },
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                widgetRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      const view = AgendaCalendarView(year: 2026, month: 8);

      await tester.runAsync(() async {
        await widgetRef.read(homeUpcomingDaysProvider.future);
        await widgetRef.read(
          agendaCalendarAppointmentDaysProvider(view).future,
        );
      });

      expect(upcomingCalls, 1);
      expect(calendarCalls, 1);

      invalidateAppointmentAfterCreate(
        widgetRef,
        clientId: 'client-1',
        day: DateTime(2026, 8, 14, 10),
      );

      await tester.runAsync(() async {
        await widgetRef.read(homeUpcomingDaysProvider.future);
        await widgetRef.read(
          agendaCalendarAppointmentDaysProvider(view).future,
        );
      });

      expect(upcomingCalls, 2);
      expect(calendarCalls, 2);
    },
  );

  testWidgets(
    'invalidateAppointmentAfterUpdate invalida homeUpcomingDays e calendário',
    (tester) async {
      var upcomingCalls = 0;
      var calendarCalls = 0;
      late WidgetRef widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeUpcomingDaysProvider.overrideWith((ref) async {
              upcomingCalls++;
              return [];
            }),
            agendaCalendarAppointmentDaysProvider.overrideWith(
              (ref, view) async {
                calendarCalls++;
                return const {};
              },
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                widgetRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      const view = AgendaCalendarView(year: 2026, month: 8);

      await tester.runAsync(() async {
        await widgetRef.read(homeUpcomingDaysProvider.future);
        await widgetRef.read(
          agendaCalendarAppointmentDaysProvider(view).future,
        );
      });

      invalidateAppointmentAfterUpdate(
        widgetRef,
        appointmentId: 'appointment-1',
        updatedDay: DateTime(2026, 8, 22, 10),
      );

      await tester.runAsync(() async {
        await widgetRef.read(homeUpcomingDaysProvider.future);
        await widgetRef.read(
          agendaCalendarAppointmentDaysProvider(view).future,
        );
      });

      expect(upcomingCalls, 2);
      expect(calendarCalls, 2);
    },
  );

  testWidgets(
    'invalidateAppointmentAfterCancellation invalida homeUpcomingDays',
    (tester) async {
      var upcomingCalls = 0;
      late WidgetRef widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeUpcomingDaysProvider.overrideWith((ref) async {
              upcomingCalls++;
              return [];
            }),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                widgetRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await widgetRef.read(homeUpcomingDaysProvider.future);
      });

      invalidateAppointmentAfterCancellation(
        widgetRef,
        appointmentId: 'appointment-1',
        clientId: 'client-1',
        day: DateTime(2026, 8, 22, 10),
      );

      await tester.runAsync(() async {
        await widgetRef.read(homeUpcomingDaysProvider.future);
      });

      expect(upcomingCalls, 2);
    },
  );

  testWidgets(
    'invalidateAppointmentAfterCompletion invalida homeUpcomingDays',
    (tester) async {
      var upcomingCalls = 0;
      late WidgetRef widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeUpcomingDaysProvider.overrideWith((ref) async {
              upcomingCalls++;
              return [];
            }),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                widgetRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await widgetRef.read(homeUpcomingDaysProvider.future);
      });

      invalidateAppointmentAfterCompletion(
        widgetRef,
        appointmentId: 'appointment-1',
        clientId: 'client-1',
        day: DateTime(2026, 8, 22, 10),
      );

      await tester.runAsync(() async {
        await widgetRef.read(homeUpcomingDaysProvider.future);
      });

      expect(upcomingCalls, 2);
    },
  );
}

class _FakeServiceRecordRepository implements ServiceRecordRepository {
  @override
  Future<ServiceRecord> create(
    ServiceRecord record, {
    String? legacyPrimaryServiceId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServiceRecord?> findByAppointmentId(String appointmentId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ServiceRecord>> findByClientId(String clientId) {
    throw UnimplementedError();
  }
}
