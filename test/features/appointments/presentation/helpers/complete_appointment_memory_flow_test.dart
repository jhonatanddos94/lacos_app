import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_flow_result.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_status.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/complete_appointment_memory_flow.dart';
import 'package:lacos_app/features/appointments/presentation/models/complete_appointment_success_action.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_form_bottom_sheet.dart';

void main() {
  group('handleCompleteAppointmentMemoryFlow', () {
    late _FakeClientMemoryRepository memoryRepository;

    setUp(() {
      memoryRepository = _FakeClientMemoryRepository();
    });

    Future<void> pumpFlow(
      WidgetTester tester, {
      required CompleteAppointmentFlowResult result,
    }) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
                        handleCompleteAppointmentMemoryFlow(
                          context: context,
                          ref: ref,
                          result: result,
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

    testWidgets('Registrar memória abre o formulário oficial', (tester) async {
      await pumpFlow(
        tester,
        result: _flowResult(
          successAction: CompleteAppointmentSuccessAction.addMemory,
        ),
      );

      expect(find.byType(MemoryFormBottomSheet), findsOneWidget);
      expect(find.text(AppStrings.memoryRegisterTitle), findsOneWidget);
      expect(
        find.text('Cadastro de memórias será implementado na próxima Sprint.'),
        findsNothing,
      );
    });

    testWidgets('clientId é recebido corretamente', (tester) async {
      await pumpFlow(
        tester,
        result: _flowResult(
          clientId: 'client-from-appointment',
          successAction: CompleteAppointmentSuccessAction.addMemory,
        ),
      );

      final sheet = tester.widget<MemoryFormBottomSheet>(
        find.byType(MemoryFormBottomSheet),
      );
      expect(sheet.clientId, 'client-from-appointment');
    });

    testWidgets('Cancelar não altera o atendimento nem cria memória', (
      tester,
    ) async {
      final result = _flowResult(
        successAction: CompleteAppointmentSuccessAction.addMemory,
      );

      await pumpFlow(tester, result: result);

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(result.appointment.status, AppointmentStatus.completed);
      expect(memoryRepository.createCalls, 0);
      expect(find.text(AppStrings.memoryRegisteredSuccess), findsNothing);
    });

    testWidgets('Salvar cria ClientMemory normalmente', (tester) async {
      await pumpFlow(
        tester,
        result: _flowResult(
          clientId: 'client-save',
          successAction: CompleteAppointmentSuccessAction.addMemory,
        ),
      );

      await tester.enterText(
        find.byType(TextFormField),
        'Prefere corte mais curto nas laterais.',
      );
      await tester.tap(find.text(AppStrings.saveMemory));
      await tester.pumpAndSettle();

      expect(memoryRepository.createCalls, 1);
      expect(memoryRepository.lastCreatedClientId, 'client-save');
      expect(find.text(AppStrings.memoryRegisteredSuccess), findsOneWidget);
      expect(find.byType(MemoryFormBottomSheet), findsNothing);
    });

    testWidgets('Agora não não abre formulário de memória', (tester) async {
      await pumpFlow(
        tester,
        result: _flowResult(
          successAction: CompleteAppointmentSuccessAction.dismiss,
        ),
      );

      expect(find.byType(MemoryFormBottomSheet), findsNothing);
      expect(memoryRepository.createCalls, 0);
    });
  });
}

CompleteAppointmentFlowResult _flowResult({
  String clientId = 'client-1',
  CompleteAppointmentSuccessAction successAction =
      CompleteAppointmentSuccessAction.dismiss,
}) {
  final now = DateTime(2026, 7, 8, 10);

  return CompleteAppointmentFlowResult(
    appointment: Appointment(
      id: 'appointment-1',
      salonId: 'salon-1',
      ownerId: 'owner-1',
      clientId: clientId,
      professionalId: 'professional-1',
      startAt: now,
      endAt: now.add(const Duration(hours: 1)),
      status: AppointmentStatus.completed,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    ),
    successAction: successAction,
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  var createCalls = 0;
  String? lastCreatedClientId;

  @override
  Future<ClientMemory> create(ClientMemory memory) async {
    createCalls++;
    lastCreatedClientId = memory.clientId;

    final now = DateTime(2026, 7, 8, 12);

    return ClientMemory(
      id: 'memory-1',
      clientId: memory.clientId,
      salonId: 'salon-1',
      ownerId: 'owner-1',
      content: memory.content,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> delete(String memoryId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ClientMemory>> findByClient({required String clientId}) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) {
    throw UnimplementedError();
  }

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> archive(String memoryId) {
    throw UnimplementedError();
  }
}
