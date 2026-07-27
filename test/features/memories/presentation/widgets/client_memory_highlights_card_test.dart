import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_durations.dart';
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

    testWidgets('uma memória: mostra conteúdo sem indicador nem rotação', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsPreviewCard(
              preview: ClientMemoryProfilePreview(
                kind: ClientMemoryProfilePreviewKind.newest,
                items: [_memory(id: 'c1', content: 'Memória única')],
              ),
              onViewAll: () {},
              rotationInterval: const Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      expect(find.text('Memória única'), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantPosition(1, 1)), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('Memória única'), findsOneWidget);
    });

    testWidgets('múltiplas: mostra uma por vez, indicador e Ver todas', (
      tester,
    ) async {
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
              rotationInterval: const Duration(days: 1),
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryImportantTitle), findsOneWidget);
      expect(find.text('Prefere café sem açúcar'), findsOneWidget);
      expect(find.text('Cliente alérgica'), findsNothing);
      expect(find.text(AppStrings.memoryImportantPosition(1, 2)), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantViewAll), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      await tester.tap(find.text(AppStrings.memoryImportantViewAll));
      await tester.pumpAndSettle();

      expect(viewAllTapped, isTrue);
    });

    testWidgets('múltiplas: troca automaticamente após o intervalo', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsPreviewCard(
              preview: ClientMemoryProfilePreview(
                kind: ClientMemoryProfilePreviewKind.newest,
                items: [
                  _memory(id: 'a', content: 'Primeira'),
                  _memory(id: 'b', content: 'Segunda'),
                ],
              ),
              onViewAll: () {},
              rotationInterval: const Duration(milliseconds: 100),
              transitionDuration: Duration.zero,
            ),
          ),
        ),
      );

      expect(find.text('Primeira'), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantPosition(1, 2)), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Segunda'), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantPosition(2, 2)), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Primeira'), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantPosition(1, 2)), findsOneWidget);
    });

    testWidgets('swipe manual avança e reinicia o ciclo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsPreviewCard(
              preview: ClientMemoryProfilePreview(
                kind: ClientMemoryProfilePreviewKind.newest,
                items: [
                  _memory(id: 'a', content: 'Primeira'),
                  _memory(id: 'b', content: 'Segunda'),
                  _memory(id: 'c', content: 'Terceira'),
                ],
              ),
              onViewAll: () {},
              rotationInterval: const Duration(days: 1),
              transitionDuration: Duration.zero,
            ),
          ),
        ),
      );

      expect(find.text('Primeira'), findsOneWidget);

      await tester.fling(
        find.text('Primeira'),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Segunda'), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantPosition(2, 3)), findsOneWidget);
    });

    testWidgets('atualização da lista preserva item atual quando possível', (
      tester,
    ) async {
      final preview = ValueNotifier(
        ClientMemoryProfilePreview(
          kind: ClientMemoryProfilePreviewKind.newest,
          items: [
            _memory(id: 'a', content: 'Primeira'),
            _memory(id: 'b', content: 'Segunda'),
          ],
        ),
      );
      addTearDown(preview.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<ClientMemoryProfilePreview>(
              valueListenable: preview,
              builder: (context, value, _) {
                return ClientMemoryHighlightsPreviewCard(
                  preview: value,
                  onViewAll: () {},
                  rotationInterval: const Duration(milliseconds: 50),
                  transitionDuration: Duration.zero,
                );
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('Segunda'), findsOneWidget);

      preview.value = ClientMemoryProfilePreview(
        kind: ClientMemoryProfilePreviewKind.newest,
        items: [
          _memory(id: 'a', content: 'Primeira'),
          _memory(id: 'b', content: 'Segunda'),
          _memory(id: 'c', content: 'Terceira'),
        ],
      );
      await tester.pump();

      expect(find.text('Segunda'), findsOneWidget);
      expect(find.text(AppStrings.memoryImportantPosition(2, 3)), findsOneWidget);
    });

    testWidgets('dispose cancela timer sem setState', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsPreviewCard(
              preview: ClientMemoryProfilePreview(
                kind: ClientMemoryProfilePreviewKind.newest,
                items: [
                  _memory(id: 'a', content: 'Primeira'),
                  _memory(id: 'b', content: 'Segunda'),
                ],
              ),
              onViewAll: () {},
              rotationInterval: const Duration(milliseconds: 30),
              transitionDuration: Duration.zero,
            ),
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('reduced motion remove duração da transição', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: ClientMemoryHighlightsPreviewCard(
                preview: ClientMemoryProfilePreview(
                  kind: ClientMemoryProfilePreviewKind.newest,
                  items: [
                    _memory(id: 'a', content: 'Primeira'),
                    _memory(id: 'b', content: 'Segunda'),
                  ],
                ),
                onViewAll: () {},
                rotationInterval: const Duration(milliseconds: 40),
                transitionDuration: AppDurations.memoryPreviewTransition,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Primeira'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump();

      expect(find.text('Segunda'), findsOneWidget);
    });

    testWidgets('pausa rotação quando app vai para background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientMemoryHighlightsPreviewCard(
              preview: ClientMemoryProfilePreview(
                kind: ClientMemoryProfilePreviewKind.newest,
                items: [
                  _memory(id: 'a', content: 'Primeira'),
                  _memory(id: 'b', content: 'Segunda'),
                ],
              ),
              onViewAll: () {},
              rotationInterval: const Duration(milliseconds: 50),
              transitionDuration: Duration.zero,
            ),
          ),
        ),
      );

      expect(find.text('Primeira'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Primeira'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('Segunda'), findsOneWidget);
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
