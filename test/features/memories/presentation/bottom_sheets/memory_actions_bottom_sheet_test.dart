import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_actions_bottom_sheet.dart';

void main() {
  group('MemoryActionsBottomSheet', () {
    testWidgets('memória ativa exibe editar, fixar e arquivar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MemoryActionsBottomSheet(isPinned: false, isArchived: false),
          ),
        ),
      );

      expect(find.text(AppStrings.editMemory), findsOneWidget);
      expect(find.text(AppStrings.memoryPinAction), findsOneWidget);
      expect(find.text(AppStrings.memoryArchiveAction), findsOneWidget);
      expect(find.text(AppStrings.memoryRestoreAction), findsNothing);
    });

    testWidgets('memória arquivada exibe restaurar e editar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MemoryActionsBottomSheet(isPinned: true, isArchived: true),
          ),
        ),
      );

      expect(find.text(AppStrings.memoryRestoreAction), findsOneWidget);
      expect(find.text(AppStrings.editMemory), findsOneWidget);
      expect(find.text(AppStrings.memoryPinAction), findsNothing);
      expect(find.text(AppStrings.memoryUnpinAction), findsNothing);
      expect(find.text(AppStrings.memoryArchiveAction), findsNothing);
    });
  });
}
