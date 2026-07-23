import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_form_bottom_sheet.dart';
import 'package:lacos_app/features/memories/presentation/helpers/memory_form_sheet_host.dart';

void main() {
  group('showMemoryFormBottomSheet', () {
    late _FakeClientMemoryRepository memoryRepository;

    setUp(() {
      memoryRepository = _FakeClientMemoryRepository();
    });

    Future<void> openSheet(
      WidgetTester tester, {
      required String clientId,
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
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showMemoryFormBottomSheet(
                          context: context,
                          clientId: clientId,
                        );
                      },
                      child: const Text('open'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('abre o formulário oficial com clientId informado', (
      tester,
    ) async {
      const clientId = 'client-42';

      await openSheet(tester, clientId: clientId);

      expect(find.byType(MemoryFormBottomSheet), findsOneWidget);

      final sheet = tester.widget<MemoryFormBottomSheet>(
        find.byType(MemoryFormBottomSheet),
      );
      expect(sheet.clientId, clientId);
      expect(sheet.memory, isNull);
      expect(find.text(AppStrings.memoryRegisterTitle), findsOneWidget);
    });

    testWidgets('fluxo pelo perfil da cliente continua usando o mesmo host', (
      tester,
    ) async {
      await openSheet(tester, clientId: 'client-profile');

      expect(find.text(AppStrings.newMemorySubtitle), findsOneWidget);
      expect(find.text(AppStrings.saveMemory), findsOneWidget);
    });
  });
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  @override
  Future<ClientMemory> create(ClientMemory memory) async {
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
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) {
    throw UnimplementedError();
  }

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

  @override
  Future<void> markMentioned(String memoryId) async {}

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

  @override
  Future<ClientMemory> restore(String memoryId) {
    throw UnimplementedError();
  }
}
