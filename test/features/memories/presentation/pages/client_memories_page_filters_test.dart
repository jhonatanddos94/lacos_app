import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/domain/repositories/client_memory_repository.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/client_memory_filters_bottom_sheet.dart';
import 'package:lacos_app/features/memories/presentation/pages/client_memories_page.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memories_header.dart';

Future<void> tapFilterChip(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(
          of: find.byType(ClientMemoryFiltersBottomSheet),
          matching: find.text(label),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ClientMemoriesPage filters', () {
    late _FakeClientMemoryRepository repository;

    setUp(() {
      repository = _FakeClientMemoryRepository();
    });

    Future<void> pumpPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientMemoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(home: ClientMemoriesPage(client: _client())),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('toque no ícone abre o bottom sheet de filtros', (
      tester,
    ) async {
      repository.memories = [_memory(id: 'm1', content: 'Conteúdo A')];

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ClientMemoryFiltersBottomSheet), findsOneWidget);
      expect(find.text(AppStrings.memoryFiltersTitle), findsOneWidget);
    });

    testWidgets('fechar sem aplicar mantém filtros anteriores', (tester) async {
      repository.memories = [
        _memory(
          id: 'm1',
          content: 'Detalhe família',
          type: ClientMemoryType.family,
        ),
        _memory(
          id: 'm2',
          content: 'Detalhe trabalho',
          type: ClientMemoryType.work,
        ),
      ];

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tapFilterChip(tester, AppStrings.memoryTypeFamily);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Detalhe família'), findsOneWidget);
      expect(find.text('Detalhe trabalho'), findsOneWidget);
    });

    testWidgets('aplicar filtro atualiza a lista visível', (tester) async {
      repository.memories = [
        _memory(
          id: 'm1',
          content: 'Detalhe família',
          type: ClientMemoryType.family,
        ),
        _memory(
          id: 'm2',
          content: 'Detalhe trabalho',
          type: ClientMemoryType.work,
        ),
      ];

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tapFilterChip(tester, AppStrings.memoryTypeFamily);
      await tester.tap(find.text(AppStrings.memoryFilterApply));
      await tester.pumpAndSettle();

      expect(find.text('Detalhe família'), findsOneWidget);
      expect(find.text('Detalhe trabalho'), findsNothing);
    });

    testWidgets('estado vazio filtrado aparece com ação de limpar', (
      tester,
    ) async {
      repository.memories = [
        _memory(
          id: 'm1',
          content: 'Detalhe família',
          type: ClientMemoryType.family,
        ),
      ];

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tapFilterChip(tester, AppStrings.memoryTypeWork);
      await tester.tap(find.text(AppStrings.memoryFilterApply));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memoryFilterEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.memoryFilterClearAction), findsOneWidget);
    });

    testWidgets('limpar filtros restaura a lista', (tester) async {
      repository.memories = [
        _memory(
          id: 'm1',
          content: 'Detalhe família',
          type: ClientMemoryType.family,
        ),
        _memory(
          id: 'm2',
          content: 'Detalhe trabalho',
          type: ClientMemoryType.work,
        ),
      ];

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tapFilterChip(tester, AppStrings.memoryTypeEvent);
      await tester.tap(find.text(AppStrings.memoryFilterApply));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.memoryFilterEmptyTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.memoryFilterClearAction));
      await tester.pumpAndSettle();

      expect(find.text('Detalhe família'), findsOneWidget);
      expect(find.text('Detalhe trabalho'), findsOneWidget);
    });

    testWidgets('indicador aparece quando filtro está ativo', (tester) async {
      repository.memories = [_memory(id: 'm1', content: 'Conteúdo')];

      await pumpPage(tester);

      expect(find.byType(ClientMemoryFiltersBottomSheet), findsNothing);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tapFilterChip(tester, AppStrings.memoryFilterOldest);
      await tester.tap(find.text(AppStrings.memoryFilterApply));
      await tester.pumpAndSettle();

      final headerButton = tester.widget<MemoryHeaderIconButton>(
        find.byType(MemoryHeaderIconButton).last,
      );
      expect(headerButton.showIndicator, isTrue);
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

ClientMemory _memory({
  required String id,
  required String content,
  ClientMemoryType type = ClientMemoryType.other,
}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: content,
    type: type,
    isActive: true,
    createdAt: DateTime(2026, 7, 8),
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
  Future<List<ClientMemory>> findByClient({
    required String clientId,
    bool includeArchived = false,
  }) async {
    if (includeArchived) {
      return memories;
    }

    return memories.where((memory) => !memory.isArchived).toList();
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
