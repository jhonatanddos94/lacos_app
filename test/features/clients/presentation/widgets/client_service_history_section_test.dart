import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';
import 'package:lacos_app/features/clients/application/providers/client_service_history_providers.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/pages/client_service_history_page.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_service_history_section.dart';

void main() {
  final client = Client(
    id: 'client-1',
    name: 'Joana',
    phone: '11999999999',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('ClientServiceHistorySection', () {
    testWidgets('exibe skeleton no loading', (tester) async {
      final completer = Completer<List<ClientServiceHistoryItem>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientServiceHistoryProvider(client.id).overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClientServiceHistorySection(
                client: client,
                onViewAll: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.clientServiceHistory), findsOneWidget);
      expect(
        find.byKey(ClientServiceHistorySection.previewSkeletonKey),
        findsOneWidget,
      );
    });

    testWidgets('empty da ficha ignora cancelados', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientServiceHistoryProvider(client.id).overrideWith(
              (ref) async => [
                _item(
                  id: 'c1',
                  kind: ClientServiceHistoryKind.canceled,
                  occurredAt: DateTime(2026, 7, 20),
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClientServiceHistorySection(
                client: client,
                onViewAll: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noServiceHistoryYet), findsOneWidget);
      expect(find.text('Cancelado'), findsNothing);
    });

    testWidgets('exibe até 3 concluídos e abre histórico completo', (
      tester,
    ) async {
      var viewAllTaps = 0;
      final items = [
        _item(id: '1', occurredAt: DateTime(2026, 7, 27), amount: 120),
        _item(
          id: 'c1',
          kind: ClientServiceHistoryKind.canceled,
          occurredAt: DateTime(2026, 7, 26),
        ),
        _item(id: '2', occurredAt: DateTime(2026, 6, 12), amount: 60),
        _item(id: '3', occurredAt: DateTime(2026, 5, 3), amount: 180),
        _item(id: '4', occurredAt: DateTime(2026, 4, 1), amount: 40),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientServiceHistoryProvider(client.id).overrideWith(
              (ref) async => items,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClientServiceHistorySection(
                client: client,
                onViewAll: () => viewAllTaps++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('27 JUL 2026'), findsOneWidget);
      expect(find.text('12 JUN 2026'), findsOneWidget);
      expect(find.text('03 MAI 2026'), findsOneWidget);
      expect(find.text('01 ABR 2026'), findsNothing);
      expect(find.text(formatServicePrice(120)), findsOneWidget);
      expect(find.text(AppStrings.clientServiceHistoryViewAll), findsOneWidget);

      await tester.tap(find.text(AppStrings.clientServiceHistoryViewAll));
      await tester.pump();
      expect(viewAllTaps, 1);
    });
  });

  group('ClientServiceHistoryPage', () {
    testWidgets('mostra completed e canceled misturados com filtros', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientServiceHistoryProvider(client.id).overrideWith(
              (ref) async => [
                _item(
                  id: '1',
                  occurredAt: DateTime(2026, 7, 27),
                  amount: 120,
                  summary: 'Hidratação',
                ),
                _item(
                  id: '2',
                  kind: ClientServiceHistoryKind.canceled,
                  occurredAt: DateTime(2026, 7, 20),
                  summary: 'Coloração',
                  reason: 'Cliente cancelou',
                ),
              ],
            ),
          ],
          child: MaterialApp(home: ClientServiceHistoryPage(client: client)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('JULHO 2026'), findsOneWidget);
      expect(find.text('Hidratação'), findsOneWidget);
      expect(find.text('Coloração'), findsOneWidget);
      expect(find.text('Concluído'), findsOneWidget);
      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.text('Motivo: Cliente cancelou'), findsOneWidget);

      await tester.tap(find.text(AppStrings.clientServiceHistoryFilterCompleted));
      await tester.pumpAndSettle();
      expect(find.text('Hidratação'), findsOneWidget);
      expect(find.text('Coloração'), findsNothing);

      await tester.tap(find.text(AppStrings.clientServiceHistoryFilterCanceled));
      await tester.pumpAndSettle();
      expect(find.text('Coloração'), findsOneWidget);
      expect(find.text('Hidratação'), findsNothing);
      expect(find.text(formatServicePrice(120)), findsNothing);
    });

    testWidgets('empty por filtro', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientServiceHistoryProvider(client.id).overrideWith(
              (ref) async => [
                _item(
                  id: 'c1',
                  kind: ClientServiceHistoryKind.canceled,
                  occurredAt: DateTime(2026, 7, 20),
                ),
              ],
            ),
          ],
          child: MaterialApp(home: ClientServiceHistoryPage(client: client)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.clientServiceHistoryFilterCompleted));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.clientServiceHistoryEmptyCompleted),
        findsOneWidget,
      );
    });
  });
}

ClientServiceHistoryItem _item({
  required String id,
  required DateTime occurredAt,
  ClientServiceHistoryKind kind = ClientServiceHistoryKind.completed,
  double? amount,
  String summary = 'Corte',
  String? reason,
}) {
  return ClientServiceHistoryItem(
    uniqueId: kind == ClientServiceHistoryKind.completed ? 'sr:$id' : 'appt:$id',
    serviceRecordId: kind == ClientServiceHistoryKind.completed ? id : null,
    appointmentId: 'appointment-$id',
    clientId: 'client-1',
    occurredAt: occurredAt,
    kind: kind,
    servicesSummary: summary,
    serviceNames: summary.split(' + '),
    professionalName: 'Ana',
    totalAmount: amount,
    cancellationReasonPreview: reason,
  );
}
