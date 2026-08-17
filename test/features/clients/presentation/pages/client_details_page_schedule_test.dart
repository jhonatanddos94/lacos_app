import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/application/use_cases/create_appointment_use_case.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment_service.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:lacos_app/features/appointments/domain/repositories/appointment_service_repository.dart';
import '../../../../helpers/appointment_schedule_test_support.dart';
import 'package:lacos_app/features/clients/application/providers/client_service_history_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/client_details_page.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

void main() {
  group('ClientDetailsPage schedule', () {
    late _FakeClientMemoryRepository memoryRepository;

    setUp(() {
      memoryRepository = _FakeClientMemoryRepository();
    });

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final createUseCase = CreateAppointmentUseCase(
        appointmentRepository: _FakeAppointmentRepository(),
        appointmentServiceRepository: _FakeAppointmentServiceRepository(),
        scheduleValidator: buildAppointmentScheduleValidator(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(memoryRepository),
            clientServiceHistoryProvider('client-1').overrideWith(
              (ref) async => const [],
            ),
            createAppointmentUseCaseProvider.overrideWithValue(createUseCase),
            appointmentFormWorkspaceOverride(),
            appointmentFormWorkingHoursOverride(),
            professionalsProvider.overrideWith(
              (ref) async => [
                Professional(
                  id: 'professional-1',
                  name: 'Leticia',
                  isActive: true,
                  createdAt: DateTime(2026, 7, 8),
                  updatedAt: DateTime(2026, 7, 8),
                ),
              ],
            ),
          ],
          child: MaterialApp(home: ClientDetailsPage(client: _client())),
        ),
      );

      await tester.pumpAndSettle();
    }

    Future<void> openScheduleForm(WidgetTester tester) async {
      await tester.tap(find.text(AppStrings.schedule));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('botão Agendar não mostra mais Em breve', (tester) async {
      await pumpPage(tester);

      expect(find.text(AppStrings.comingSoon), findsNothing);
      expect(find.text(AppStrings.scheduleActionSubtitle), findsOneWidget);
    });

    testWidgets(
      'Q: Agendar na ficha auto-seleciona a única Professional',
      (tester) async {
        await pumpPage(tester);
        await openScheduleForm(tester);

        expect(
          find.text(AppStrings.appointmentFormCreateTitle),
          findsOneWidget,
        );
        expect(find.text('Maria'), findsAtLeastNWidgets(1));
        expect(
          find.text(AppStrings.appointmentChooseClientPrompt),
          findsNothing,
        );
        expect(find.text('Leticia'), findsOneWidget);
        expect(
          find.text(AppStrings.appointmentChooseProfessionalPrompt),
          findsNothing,
        );
      },
    );

    Future<void> closeScheduleForm(WidgetTester tester) async {
      final formContext = tester.element(
        find.text(AppStrings.appointmentFormCreateTitle),
      );
      Navigator.of(formContext).pop();
      await tester.pumpAndSettle();
    }

    testWidgets('cancelamento do sheet não mostra sucesso', (tester) async {
      await pumpPage(tester);
      await openScheduleForm(tester);
      await closeScheduleForm(tester);

      expect(find.text(AppStrings.appointmentCreatedSuccess), findsNothing);
      expect(find.text(AppStrings.clientDetailsTitle), findsOneWidget);
    });

    testWidgets('ficha permanece aberta após cancelamento', (tester) async {
      await pumpPage(tester);
      await openScheduleForm(tester);
      await closeScheduleForm(tester);

      expect(find.text('Maria'), findsAtLeastNWidgets(1));
      expect(find.text(AppStrings.clientDetailsTitle), findsOneWidget);
    });
  });
}

Client _client() {
  final now = DateTime(2026, 7, 8);

  return Client(
    id: 'client-1',
    name: 'Maria',
    phone: '11999999999',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppointmentRepository implements AppointmentRepository {
  @override
  Future<Appointment> create(Appointment appointment) async {
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
  }) async => null;

  @override
  Future<List<Appointment>> findCanceledByClientId(String clientId) async {
    return const [];
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

class _FakeAppointmentServiceRepository
    implements AppointmentServiceRepository {
  @override
  Future<List<AppointmentService>> createMany({
    required String appointmentId,
    required List<AppointmentService> services,
  }) async {
    final now = DateTime(2026, 7, 8, 10);
    return services
        .map(
          (service) => AppointmentService(
            id: 'line-${service.displayOrder}',
            appointmentId: appointmentId,
            serviceId: service.serviceId,
            salonId: service.salonId,
            ownerId: service.ownerId,
            priceAtBooking: service.priceAtBooking,
            durationMinutesAtBooking: service.durationMinutesAtBooking,
            displayOrder: service.displayOrder,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> deleteByAppointment(String appointmentId) async {}

  @override
  Future<List<AppointmentService>> findByAppointment(String appointmentId) {
    return Future.value(const []);
  }

  @override
  Future<List<AppointmentService>> findByAppointments(
    List<String> appointmentIds,
  ) {
    return Future.value(const []);
  }
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    return const [];
  }

  @override
  Future<void> markMentioned(String memoryId) async {}

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

  @override
  Future<ClientMemory> archive(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> create(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String memoryId) => throw UnimplementedError();

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<ClientMemory> restore(String memoryId) => throw UnimplementedError();
}
