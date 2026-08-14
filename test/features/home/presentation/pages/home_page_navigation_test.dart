import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/time/application/providers/clock_providers.dart';
import 'package:lacos_app/core/workspace/application/providers/workspace_providers.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/application/providers/calendar_today_providers.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_details_providers.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_details_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_form_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_professional_section.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/clients/application/providers/client_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/domain/repositories/client_repository.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_form_bottom_sheet.dart';
import 'package:lacos_app/features/home/presentation/pages/home_page.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_attention_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_header.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_next_appointment_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_quick_actions_section.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_today_summary_section.dart';
import 'package:lacos_app/features/home/application/providers/home_upcoming_days_provider.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/professional/application/providers/professional_providers.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/presentation/navigation/professional_profile_navigation.dart';
import 'package:lacos_app/features/professional/presentation/pages/professional_profile_page.dart';
import 'package:lacos_app/features/salon/presentation/navigation/salon_navigation.dart';
import 'package:lacos_app/features/salon/presentation/pages/salon_page.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/shell/application/models/app_shell_tab.dart';
import 'package:lacos_app/features/shell/application/providers/app_shell_providers.dart';

import '../../../../helpers/home_test_fixtures.dart';

void main() {
  final now = homeTestNow;
  final today = AgendaDay.from(now);

  setUp(() {
    resetAgendaAppointmentOpenGuardForTest();
    resetProfessionalProfileNavigationGuardForTest();
    resetSalonNavigationGuardForTest();
  });
  tearDown(() {
    resetAgendaAppointmentOpenGuardForTest();
    resetProfessionalProfileNavigationGuardForTest();
    resetSalonNavigationGuardForTest();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    List<AgendaAppointmentDisplay> appointments = const [],
    ClientMemoryRepository? memoryRepository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          professionalsProvider.overrideWith(
            (ref) async => [
              Professional(
                id: 'professional-1',
                name: 'Maria Santos',
                isActive: true,
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => appointments,
          ),
          homeUpcomingDaysProvider.overrideWith((ref) async => const []),
          appointmentsByDayProvider.overrideWith((ref, day) async => const []),
          clientRepositoryProvider.overrideWithValue(_FakeClientRepository()),
          clientMemoryRepositoryProvider.overrideWithValue(
            memoryRepository ?? _FakeClientMemoryRepository(),
          ),
          appointmentDetailsProvider.overrideWith((ref, query) async {
            return AppointmentDetails(
              appointment: Appointment(
                id: query.appointmentId,
                salonId: 'salon-1',
                ownerId: 'owner-1',
                clientId: 'client-1',
                professionalId: 'professional-1',
                startAt: query.day,
                endAt: query.day.add(const Duration(hours: 1)),
                status: AppointmentStatus.pending,
                isActive: true,
                createdAt: query.day,
                updatedAt: query.day,
              ),
              client: Client(
                id: 'client-1',
                name: 'Josefa',
                phone: '11999999999',
                isActive: true,
                createdAt: query.day,
                updatedAt: query.day,
              ),
              professional: Professional(
                id: 'professional-1',
                name: 'Maria Santos',
                isActive: true,
                createdAt: query.day,
                updatedAt: query.day,
              ),
              services: [
                Service(
                  id: 'service-1',
                  name: 'Hidratação',
                  durationMinutes: 60,
                  price: 80,
                  isActive: true,
                  createdAt: query.day,
                  updatedAt: query.day,
                ),
              ],
            );
          }),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('avatar abre Meu perfil e não abre o sheet Conta', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomeHeader.profileAvatarKey));
    await tester.pumpAndSettle();

    expect(find.byType(ProfessionalProfilePage), findsOneWidget);
    expect(find.text(AppStrings.profile), findsWidgets);
    expect(find.text(AppStrings.logout), findsOneWidget);
    expect(find.text(AppStrings.comingSoon), findsNothing);
  });

  testWidgets('storefront abre Meu salão', (tester) async {
    await pumpHome(tester);

    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    await tester.tap(find.byKey(HomeHeader.salonButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(SalonPage), findsOneWidget);
    expect(find.text(AppStrings.mySalon), findsWidgets);
  });

  testWidgets('O: Home → Agendar auto-seleciona a única Professional', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.ensureVisible(
      find.byKey(HomeTodaySummarySection.newAppointmentCtaKey),
    );
    await tester.tap(find.byKey(HomeTodaySummarySection.newAppointmentCtaKey));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentFormBottomSheet), findsOneWidget);
    expect(find.text(AppStrings.appointmentChooseProfessionalPrompt), findsNothing);
    expect(find.byKey(AppointmentProfessionalSection.readOnlyKey), findsOneWidget);
  });

  testWidgets('nova cliente abre o formulário oficial', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomeQuickActionsSection.newClientKey));
    await tester.pumpAndSettle();

    expect(find.byType(ClientFormBottomSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ClientFormBottomSheet),
        matching: find.text(AppStrings.newClientTitle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Buscar cliente solicita a tab Clientes com foco na busca', (
    tester,
  ) async {
    late WidgetRef widgetRef;

    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          professionalsProvider.overrideWith(
            (ref) async => [
              Professional(
                id: 'professional-1',
                name: 'Maria Santos',
                isActive: true,
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => const [],
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const HomePage();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeQuickActionsSection.searchClientKey));
    await tester.pump();

    expect(widgetRef.read(appShellTabProvider), AppShellTab.clients);
    expect(widgetRef.read(clientsFocusSearchRequestProvider), 1);
  });

  testWidgets('próximo atendimento abre o fluxo oficial', (tester) async {
    await pumpHome(
      tester,
      appointments: [
        homeTestAppointment(
          id: 'upcoming',
          clientName: 'Josefa',
          startAt: DateTime(2026, 8, 13, 16, 0),
        ),
      ],
    );

    await tester.tap(find.byKey(HomeNextAppointmentCard.sectionKey));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
  });

  testWidgets('atendimento current abre preparação imediatamente', (
    tester,
  ) async {
    final memoryRepository = _PendingClientMemoryRepository();

    await pumpHome(
      tester,
      appointments: [
        homeTestAppointment(
          id: 'current',
          clientName: 'Josefa',
          startAt: DateTime(2026, 8, 13, 13, 30),
        ),
      ],
      memoryRepository: memoryRepository,
    );

    await tester.tap(find.byKey(HomeNextAppointmentCard.sectionKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
    expect(find.text('Josefa'), findsWidgets);
    expect(
      find.byKey(AppointmentPreparationBottomSheet.memoriesLoadingKey),
      findsOneWidget,
    );
    expect(memoryRepository.findByClientCalls, 1);
  });

  testWidgets('um overdue abre o atendimento', (tester) async {
    await pumpHome(
      tester,
      appointments: [
        homeTestAppointment(
          id: 'overdue',
          clientName: 'Atrasada',
          startAt: DateTime(2026, 8, 13, 10, 0),
        ),
      ],
    );

    await tester.tap(find.byKey(HomeAttentionSection.sectionKey));
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
  });

  testWidgets('vários overdue pedem a Agenda', (tester) async {
    late WidgetRef widgetRef;

    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appClockProvider.overrideWithValue(FakeAppClock(now)),
          calendarTodayProvider.overrideWithValue(today),
          workspaceProvider.overrideWith((ref) async => homeTestWorkspace()),
          professionalsProvider.overrideWith(
            (ref) async => [
              Professional(
                id: 'professional-1',
                name: 'Maria Santos',
                isActive: true,
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
          agendaAppointmentsDisplayProvider.overrideWith(
            (ref, day) async => [
              homeTestAppointment(
                id: 'a',
                clientName: 'A',
                startAt: DateTime(2026, 8, 13, 9, 0),
              ),
              homeTestAppointment(
                id: 'b',
                clientName: 'B',
                startAt: DateTime(2026, 8, 13, 11, 0),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              return const HomePage();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeAttentionSection.sectionKey));
    await tester.pump();

    expect(widgetRef.read(appShellTabProvider), AppShellTab.agenda);
  });

  testWidgets('duplo toque não empilha dois formulários de agendamento', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.ensureVisible(
      find.byKey(HomeTodaySummarySection.newAppointmentCtaKey),
    );
    await tester.tap(find.byKey(HomeTodaySummarySection.newAppointmentCtaKey));
    await tester.tap(
      find.byKey(HomeTodaySummarySection.newAppointmentCtaKey),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentFormBottomSheet), findsOneWidget);
  });

  testWidgets('duplo toque no Agendar não empilha dois formulários', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(HomeQuickActionsSection.newAppointmentKey));
    await tester.tap(
      find.byKey(HomeQuickActionsSection.newAppointmentKey),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentFormBottomSheet), findsOneWidget);
  });

  testWidgets('duplo toque no próximo atendimento não empilha detalhes', (
    tester,
  ) async {
    await pumpHome(
      tester,
      appointments: [
        homeTestAppointment(
          id: 'upcoming',
          clientName: 'Josefa',
          startAt: DateTime(2026, 8, 13, 16, 0),
        ),
      ],
    );

    await tester.tap(find.byKey(HomeNextAppointmentCard.sectionKey));
    await tester.tap(
      find.byKey(HomeNextAppointmentCard.sectionKey),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
  });
}

class _FakeClientRepository implements ClientRepository {
  @override
  Future<Client> create({
    required String name,
    required String phone,
    DateTime? birthDate,
    String? instagram,
    String? photoPath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String clientId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Client>> findAll() async => const [];

  @override
  Future<Client> update(Client client, {String? photoPath}) {
    throw UnimplementedError();
  }
}

class _PendingClientMemoryRepository extends _FakeClientMemoryRepository {
  final _pending = Completer<List<ClientMemory>>();
  var findByClientCalls = 0;

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) {
    findByClientCalls++;
    return _pending.future;
  }
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  @override
  Future<ClientMemory> archive(String memoryId) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> create(ClientMemory memory) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String memoryId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async => const [];

  @override
  Future<void> markMentioned(String memoryId) async {}

  @override
  Future<ClientMemory> restore(String memoryId) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

  @override
  Future<ClientMemory> update(ClientMemory memory) {
    throw UnimplementedError();
  }
}
