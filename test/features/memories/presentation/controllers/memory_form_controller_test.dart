import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/presentation/controllers/memory_form_controller.dart';

void main() {
  group('MemoryFormController', () {
    late _FakeClientMemoryRepository repository;
    late MemoryFormController controller;

    setUp(() {
      repository = _FakeClientMemoryRepository();
      controller = MemoryFormController(repository);
    });

    test('create usa defaults oficiais', () {
      controller.initializeForCreate();

      expect(controller.state.type, ClientMemoryType.other);
      expect(controller.state.priority, ClientMemoryPriority.normal);
      expect(controller.state.isPinned, isFalse);
      expect(controller.state.isEditing, isFalse);
    });

    test('edit preenche valores atuais', () {
      final memory = _sampleMemory(
        content: 'Prefere café sem açúcar',
        type: ClientMemoryType.preference,
        priority: ClientMemoryPriority.high,
        isPinned: true,
      );

      controller.initializeForEdit(memory);

      expect(controller.state.content, memory.content);
      expect(controller.state.type, ClientMemoryType.preference);
      expect(controller.state.priority, ClientMemoryPriority.high);
      expect(controller.state.isPinned, isTrue);
      expect(controller.state.isEditing, isTrue);
    });

    test('save create envia campos editáveis', () async {
      controller.initializeForCreate();
      controller
        ..setContent('Cliente gosta de conversar sobre família')
        ..setType(ClientMemoryType.family)
        ..setPriority(ClientMemoryPriority.low)
        ..setPinned(true);

      final saved = await controller.save(clientId: 'client-1');

      expect(saved, isNotNull);
      expect(
        repository.lastCreated?.content,
        'Cliente gosta de conversar sobre família',
      );
      expect(repository.lastCreated?.type, ClientMemoryType.family);
      expect(repository.lastCreated?.priority, ClientMemoryPriority.low);
      expect(repository.lastCreated?.isPinned, isTrue);
    });

    test('save edit preserva campos não editáveis', () async {
      final memory = _sampleMemory(
        content: 'Original',
        isPinned: false,
        lastMentionedAt: DateTime(2026, 7, 1),
        isArchived: false,
      );

      controller.initializeForEdit(memory);
      controller
        ..setContent('Atualizado')
        ..setType(ClientMemoryType.work)
        ..setPriority(ClientMemoryPriority.high)
        ..setPinned(true);

      final saved = await controller.save(clientId: 'client-1');

      expect(saved, isNotNull);
      expect(repository.lastUpdated?.content, 'Atualizado');
      expect(repository.lastUpdated?.type, ClientMemoryType.work);
      expect(repository.lastUpdated?.priority, ClientMemoryPriority.high);
      expect(repository.lastUpdated?.isPinned, isTrue);
      expect(repository.lastUpdated?.lastMentionedAt, memory.lastMentionedAt);
      expect(repository.lastUpdated?.isArchived, isFalse);
    });

    test('validação impede conteúdo vazio', () async {
      controller.initializeForCreate();
      controller.setContent('   ');

      final saved = await controller.save(clientId: 'client-1');

      expect(saved, isNull);
      expect(controller.state.contentError, AppStrings.memoryRequired);
    });

    test('validação impede conteúdo acima do limite', () async {
      controller.initializeForCreate();
      controller.setContent('a' * (AppFieldLimits.memoryContent + 1));

      final saved = await controller.save(clientId: 'client-1');

      expect(saved, isNull);
      expect(controller.state.contentError, AppStrings.memoryMaxLengthError);
    });

    test('impede duplo submit', () async {
      controller.initializeForCreate();
      controller.setContent('Conteúdo válido');
      repository.createDelay = const Duration(milliseconds: 50);

      final first = controller.save(clientId: 'client-1');
      final second = controller.save(clientId: 'client-1');

      expect(await second, isNull);
      expect(await first, isNotNull);
      expect(repository.createCalls, 1);
    });
  });
}

ClientMemory _sampleMemory({
  required String content,
  ClientMemoryType type = ClientMemoryType.other,
  ClientMemoryPriority priority = ClientMemoryPriority.normal,
  bool isPinned = false,
  DateTime? lastMentionedAt,
  bool isArchived = false,
}) {
  return ClientMemory(
    id: 'memory-1',
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: content,
    type: type,
    priority: priority,
    isPinned: isPinned,
    lastMentionedAt: lastMentionedAt,
    isArchived: isArchived,
    isActive: true,
  );
}

class _FakeClientMemoryRepository implements ClientMemoryRepository {
  ClientMemory? lastCreated;
  ClientMemory? lastUpdated;
  var createCalls = 0;
  Duration createDelay = Duration.zero;

  @override
  Future<ClientMemory> create(ClientMemory memory) async {
    createCalls++;
    await Future<void>.delayed(createDelay);
    lastCreated = memory;
    return memory.copyWith(id: 'memory-new');
  }

  @override
  Future<void> delete(String memoryId) async {}

  @override
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    return [];
  }

  @override
  Future<ClientMemory> update(ClientMemory memory) async {
    lastUpdated = memory;
    return memory;
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
