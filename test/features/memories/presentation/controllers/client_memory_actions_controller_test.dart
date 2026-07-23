import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/presentation/controllers/client_memory_actions_controller.dart';

void main() {
  group('ClientMemoryActionsController', () {
    late _FakeClientMemoryRepository repository;
    late ClientMemoryActionsController controller;

    setUp(() {
      repository = _FakeClientMemoryRepository();
      controller = ClientMemoryActionsController(repository);
    });

    test('restore restaura memória arquivada', () async {
      final memory = _memory(isArchived: true);

      final restored = await controller.restore(memory);

      expect(restored, isNotNull);
      expect(restored!.isArchived, isFalse);
      expect(repository.restoreCalls, 1);
    });

    test('restore rejeita memória não arquivada', () async {
      final memory = _memory(isArchived: false);

      final restored = await controller.restore(memory);

      expect(restored, isNull);
      expect(repository.restoreCalls, 0);
      expect(controller.state.errorMessage, AppStrings.memoryRestoreError);
    });

    test('setPinned rejeita memória arquivada', () async {
      final memory = _memory(isArchived: true, isPinned: true);

      final updated = await controller.setPinned(
        memory: memory,
        isPinned: false,
      );

      expect(updated, isNull);
      expect(repository.setPinnedCalls, 0);
      expect(controller.state.errorMessage, AppStrings.memoryPinError);
    });

    test('archive rejeita memória já arquivada', () async {
      final memory = _memory(isArchived: true);

      final archived = await controller.archive(memory);

      expect(archived, isNull);
      expect(repository.archiveCalls, 0);
      expect(controller.state.errorMessage, AppStrings.memoryArchiveError);
    });
  });
}

ClientMemory _memory({required bool isArchived, bool isPinned = false}) {
  return ClientMemory(
    id: 'memory-1',
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: 'Conteúdo',
    isArchived: isArchived,
    isPinned: isPinned,
    isActive: true,
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  var restoreCalls = 0;
  var setPinnedCalls = 0;
  var archiveCalls = 0;

  @override
  Future<ClientMemory> restore(String memoryId) async {
    restoreCalls++;
    return _memory(isArchived: false);
  }

  @override
  Future<ClientMemory> setPinned({
    required String memoryId,
    required bool isPinned,
  }) async {
    setPinnedCalls++;
    return _memory(isArchived: false, isPinned: isPinned);
  }

  @override
  Future<ClientMemory> archive(String memoryId) async {
    archiveCalls++;
    return _memory(isArchived: true);
  }

  @override
  Future<ClientMemory> create(ClientMemory memory) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String memoryId) => throw UnimplementedError();

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markMentioned(String memoryId) async {}

  @override
  Future<void> touchMentioned({required List<String> memoryIds}) async {}

  @override
  Future<ClientMemory> update(ClientMemory memory) =>
      throw UnimplementedError();
}
