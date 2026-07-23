import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_details_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/agenda_appointment_open_flow.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';

void main() {
  group('openAgendaAppointmentFlow', () {
    late _FakeClientMemoryRepository memoryRepository;

    setUp(() {
      memoryRepository = _FakeClientMemoryRepository();
    });

    AgendaAppointmentDisplay eligibleAppointment({
      AppointmentStatus status = AppointmentStatus.pending,
    }) {
      final now = DateTime.now();
      final startAt = now.add(const Duration(minutes: 10));
      final endAt = startAt.add(const Duration(hours: 1));

      return AgendaAppointmentDisplay(
        appointmentId: 'appointment-1',
        clientId: 'client-1',
        clientName: 'Maria Silva',
        servicesSummary: 'Corte',
        startAt: startAt,
        endAt: endAt,
        status: status,
      );
    }

    Future<void> pumpFlow(
      WidgetTester tester, {
      required AgendaAppointmentDisplay appointment,
      required DateTime now,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(memoryRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        openAgendaAppointmentFlow(
                          context: context,
                          ref: ref,
                          appointment: appointment,
                          now: now,
                        );
                      },
                      child: const Text('open-flow'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();
    }

    testWidgets('atendimento elegível abre preparação antes dos detalhes', (
      tester,
    ) async {
      memoryRepository.memories = [
        _memory(content: 'Prefere conversar pouco.'),
      ];

      final now = DateTime.now();
      final appointment = eligibleAppointment();

      await pumpFlow(
        tester,
        appointment: appointment,
        now: now,
      );

      expect(find.byType(AppointmentPreparationBottomSheet), findsOneWidget);
      expect(find.text('Prefere conversar pouco.'), findsOneWidget);
      expect(find.byType(AppointmentDetailsBottomSheet), findsNothing);

      await tester.tap(find.text(AppStrings.appointmentPreparationContinue));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
      expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
    });

    testWidgets('atendimento não elegível abre detalhes direto', (
      tester,
    ) async {
      final now = DateTime.now();
      final appointment = AgendaAppointmentDisplay(
        appointmentId: 'appointment-2',
        clientId: 'client-2',
        clientName: 'Ana Costa',
        servicesSummary: 'Coloração',
        startAt: now.add(const Duration(hours: 3)),
        endAt: now.add(const Duration(hours: 4)),
        status: AppointmentStatus.pending,
      );

      await pumpFlow(
        tester,
        appointment: appointment,
        now: now,
      );

      expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
      expect(find.byType(AppointmentDetailsBottomSheet), findsOneWidget);
    });

    testWidgets('Agora não fecha fluxo sem abrir detalhes', (tester) async {
      final now = DateTime.now();

      await pumpFlow(
        tester,
        appointment: eligibleAppointment(),
        now: now,
      );

      await tester.tap(find.text(AppStrings.appointmentPreparationNotNow));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentPreparationBottomSheet), findsNothing);
      expect(find.byType(AppointmentDetailsBottomSheet), findsNothing);
    });

    testWidgets('nenhuma alteração de status ocorre', (tester) async {
      final appointment = eligibleAppointment(
        status: AppointmentStatus.confirmed,
      );

      await pumpFlow(
        tester,
        appointment: appointment,
        now: DateTime.now(),
      );

      expect(appointment.status, AppointmentStatus.confirmed);
    });
  });
}

ClientMemory _memory({required String content}) {
  final now = DateTime(2026, 7, 10, 12);

  return ClientMemory(
    id: 'memory-1',
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: content,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  List<ClientMemory> memories = [];

  @override
  Future<ClientMemory> create(ClientMemory memory) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String memoryId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ClientMemory>> findByClient({required String clientId}) async {
    return memories;
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) {
    throw UnimplementedError();
  }

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}
}
