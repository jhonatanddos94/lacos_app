import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_filter_service.dart';

void main() {
  group('ClientServiceHistoryFilterService', () {
    final items = [
      _item(id: '1', kind: ClientServiceHistoryKind.completed),
      _item(id: '2', kind: ClientServiceHistoryKind.canceled),
      _item(id: '3', kind: ClientServiceHistoryKind.completed),
    ];

    test('Todos mantém completed + canceled', () {
      final filtered = ClientServiceHistoryFilterService.apply(
        items: items,
        filter: ClientServiceHistoryFilter.all,
      );
      expect(filtered, hasLength(3));
    });

    test('Concluídos filtra só completed', () {
      final filtered = ClientServiceHistoryFilterService.apply(
        items: items,
        filter: ClientServiceHistoryFilter.completed,
      );
      expect(
        filtered.map((item) => item.uniqueId),
        ['sr:1', 'sr:3'],
      );
    });

    test('Cancelados filtra só canceled', () {
      final filtered = ClientServiceHistoryFilterService.apply(
        items: items,
        filter: ClientServiceHistoryFilter.canceled,
      );
      expect(filtered.map((item) => item.uniqueId), ['appt:2']);
    });
  });
}

ClientServiceHistoryItem _item({
  required String id,
  required ClientServiceHistoryKind kind,
}) {
  return ClientServiceHistoryItem(
    uniqueId: kind == ClientServiceHistoryKind.completed ? 'sr:$id' : 'appt:$id',
    serviceRecordId: kind == ClientServiceHistoryKind.completed ? id : null,
    appointmentId: 'appointment-$id',
    clientId: 'client-1',
    occurredAt: DateTime(2026, 7, 1),
    kind: kind,
    servicesSummary: 'Corte',
    serviceNames: const ['Corte'],
  );
}
