import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_preview.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_preview_service.dart';

void main() {
  group('ClientServiceHistoryPreviewService', () {
    test('retorna vazio para lista vazia', () {
      final preview = ClientServiceHistoryPreviewService.resolve(const []);
      expect(preview, ClientServiceHistoryPreview.empty);
    });

    test('ignora cancelados e limita a 3 concluídos recentes', () {
      final items = [
        _item(
          id: 'c1',
          kind: ClientServiceHistoryKind.canceled,
          occurredAt: DateTime(2026, 7, 28),
        ),
        _item(id: '1', occurredAt: DateTime(2026, 1, 10)),
        _item(id: '2', occurredAt: DateTime(2026, 7, 27)),
        _item(id: '3', occurredAt: DateTime(2026, 6, 12)),
        _item(id: '4', occurredAt: DateTime(2026, 5, 3)),
        _item(id: '5', occurredAt: DateTime(2026, 3, 1)),
      ];

      final preview = ClientServiceHistoryPreviewService.resolve(items);

      expect(preview.items, hasLength(ClientServiceHistoryPreview.maxItems));
      expect(
        preview.items.map((item) => item.serviceRecordId),
        ['2', '3', '4'],
      );
      expect(
        preview.items.every(
          (item) => item.kind == ClientServiceHistoryKind.completed,
        ),
        isTrue,
      );
    });

    test('ficha sem concluídos fica vazia mesmo com cancelados', () {
      final preview = ClientServiceHistoryPreviewService.resolve([
        _item(
          id: 'c1',
          kind: ClientServiceHistoryKind.canceled,
          occurredAt: DateTime(2026, 7, 28),
        ),
      ]);

      expect(preview.isEmpty, isTrue);
    });
  });
}

ClientServiceHistoryItem _item({
  required String id,
  required DateTime occurredAt,
  ClientServiceHistoryKind kind = ClientServiceHistoryKind.completed,
}) {
  return ClientServiceHistoryItem(
    uniqueId: kind == ClientServiceHistoryKind.completed ? 'sr:$id' : 'appt:$id',
    serviceRecordId: kind == ClientServiceHistoryKind.completed ? id : null,
    appointmentId: 'appointment-$id',
    clientId: 'client-1',
    occurredAt: occurredAt,
    kind: kind,
    servicesSummary: 'Corte',
    serviceNames: const ['Corte'],
    totalAmount: kind == ClientServiceHistoryKind.completed ? 100 : null,
  );
}
