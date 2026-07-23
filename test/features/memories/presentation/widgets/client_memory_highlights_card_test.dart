import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_highlights.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_profile_preview.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memory_highlights_card.dart';

void main() {
  group('ClientMemoryHighlightsCard', () {
    testWidgets('não renderiza quando highlights está vazio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsCard(
              highlights: ClientMemoryHighlights.empty,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryImportantTitle), findsNothing);
    });

    testWidgets('renderiza grupos fixadas e recentes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsCard(
              highlights: ClientMemoryHighlights(
                pinned: [_memory(id: 'p1', content: 'Alergia à amônia')],
                recent: [_memory(id: 'r1', content: 'Vai casar em novembro')],
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryImportantTitle), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantPinnedGroup), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantRecentGroup), findsOneWidget);
      expect(find.text('Alergia à amônia'), findsOneWidget);
      expect(find.text('Vai casar em novembro'), findsOneWidget);
    });

    testWidgets('oculta grupo fixadas quando vazio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsCard(
              highlights: ClientMemoryHighlights(
                recent: [_memory(id: 'r1', content: 'Recente')],
              ),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryImportantPinnedGroup), findsNothing);
      expect(find.text(AppStrings.memoryImportantRecentGroup), findsOneWidget);
    });

    testWidgets('mostra ação Utilizada quando interativo', (tester) async {
      String? toggledId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsCard(
              highlights: ClientMemoryHighlights(
                pinned: [_memory(id: 'p1', content: 'Fixada')],
              ),
              usedMemoryIds: const {'p1'},
              onToggleUsed: (memoryId) => toggledId = memoryId,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryImportantUsedAction), findsOneWidget);

      await tester.tap(find.text(AppStrings.memoryImportantUsedAction));
      await tester.pumpAndSettle();

      expect(toggledId, 'p1');
    });
  });

  group('ClientMemoryHighlightsPreviewCard', () {
    testWidgets('não renderiza quando preview está vazio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsPreviewCard(
              preview: ClientMemoryProfilePreview.empty,
              onViewAll: () {},
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryImportantTitle), findsNothing);
    });

    testWidgets('renderiza preview e botão Ver todas', (tester) async {
      var viewAllTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsPreviewCard(
              preview: ClientMemoryProfilePreview(
                kind: ClientMemoryProfilePreviewKind.pinned,
                items: [
                  _memory(id: 'p1', content: 'Prefere café sem açúcar'),
                  _memory(id: 'p2', content: 'Cliente alérgica'),
                ],
              ),
              onViewAll: () => viewAllTapped = true,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryImportantTitle), findsOneWidget);
      expect(find.text('Prefere café sem açúcar'), findsOneWidget);
      expect(find.text('Cliente alérgica'), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantViewAll), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);

      await tester.tap(find.text(AppStrings.memoryImportantViewAll));
      await tester.pumpAndSettle();

      expect(viewAllTapped, isTrue);
    });

    testWidgets('preview comum não exibe ícone de fixada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsPreviewCard(
              preview: ClientMemoryProfilePreview(
                kind: ClientMemoryProfilePreviewKind.newest,
                items: [_memory(id: 'c1', content: 'Memória comum')],
              ),
              onViewAll: () {},
            ),
          ),
        ),
      );

      expect(find.text('Memória comum'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });

  group('ClientMemoryHighlightsCard atendimento', () {
    testWidgets('não renderiza quando há apenas memórias comuns', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsCard(
              highlights: ClientMemoryHighlights.empty,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryImportantTitle), findsNothing);
    });
  });
}

ClientMemory _memory({required String id, required String content}) {
  return ClientMemory(
    id: id,
    clientId: 'client-1',
    salonId: 'salon-1',
    ownerId: 'owner-1',
    content: content,
    isActive: true,
  );
}
