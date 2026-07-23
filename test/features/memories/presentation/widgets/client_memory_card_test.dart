import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/presentation/widgets/client_memory_card.dart';

void main() {
  group('ClientMemoryCard', () {
    testWidgets('exibe categoria, prioridade alta e indicação de fixada', (
      tester,
    ) async {
      final memory = ClientMemory(
        id: 'memory-1',
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Prefere horários pela manhã',
        type: ClientMemoryType.preference,
        priority: ClientMemoryPriority.high,
        isPinned: true,
        isActive: true,
        createdAt: DateTime(2026, 7, 8),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ClientMemoryCard(memory: memory)),
        ),
      );

      expect(find.text('Prefere horários pela manhã'), findsOneWidget);
      expect(find.text(AppStrings.memoryTypePreference), findsOneWidget);
      expect(find.text(AppStrings.memoryPriorityHigh), findsOneWidget);
      expect(find.text(AppStrings.memoryPinnedBadge), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    });

    testWidgets('prioridade normal não aparece como destaque', (tester) async {
      final memory = ClientMemory(
        id: 'memory-1',
        clientId: 'client-1',
        salonId: 'salon-1',
        ownerId: 'owner-1',
        content: 'Gosta de música suave',
        type: ClientMemoryType.personal,
        priority: ClientMemoryPriority.normal,
        isActive: true,
        createdAt: DateTime(2026, 7, 8),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ClientMemoryCard(memory: memory)),
        ),
      );

      expect(find.text(AppStrings.memoryTypePersonal), findsOneWidget);
      expect(find.text(AppStrings.memoryPriorityNormal), findsNothing);
    });
  });
}
