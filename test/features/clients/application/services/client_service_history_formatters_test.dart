import 'package:flutter_test/flutter_test.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_kind.dart';
import 'package:lacos_app/features/clients/application/services/client_service_history_formatters.dart';

void main() {
  group('ClientServiceHistoryGrouper', () {
    test('retorna vazio para lista vazia', () {
      expect(ClientServiceHistoryGrouper.groupByMonth(const []), isEmpty);
    });

    test('agrupa completed + canceled no mesmo mês', () {
      final items = [
        _item(
          id: 'may',
          kind: ClientServiceHistoryKind.completed,
          occurredAt: DateTime(2026, 5, 3),
        ),
        _item(
          id: 'jul-done',
          kind: ClientServiceHistoryKind.completed,
          occurredAt: DateTime(2026, 7, 27),
        ),
        _item(
          id: 'jul-canceled',
          kind: ClientServiceHistoryKind.canceled,
          occurredAt: DateTime(2026, 7, 20),
        ),
        _item(
          id: 'jun',
          kind: ClientServiceHistoryKind.canceled,
          occurredAt: DateTime(2026, 6, 12),
        ),
      ];

      final groups = ClientServiceHistoryGrouper.groupByMonth(items);

      expect(groups, hasLength(3));
      expect(groups[0].label, 'JULHO 2026');
      expect(
        groups[0].items.map((item) => item.uniqueId),
        ['sr:jul-done', 'appt:jul-canceled'],
      );
      expect(groups[1].label, 'JUNHO 2026');
      expect(groups[2].label, 'MAIO 2026');
    });

    test('respeita virada de ano', () {
      final items = [
        _item(id: 'jan', occurredAt: DateTime(2027, 1, 5)),
        _item(id: 'dec', occurredAt: DateTime(2026, 12, 20)),
      ];

      final groups = ClientServiceHistoryGrouper.groupByMonth(items);

      expect(groups.map((group) => group.label), [
        'JANEIRO 2027',
        'DEZEMBRO 2026',
      ]);
    });
  });

  group('ClientServiceHistoryServicesLabel', () {
    test('um serviço', () {
      expect(
        ClientServiceHistoryServicesLabel.fromNames(const ['Corte']),
        'Corte',
      );
    });

    test('dois serviços', () {
      expect(
        ClientServiceHistoryServicesLabel.fromNames(const [
          'Corte',
          'Hidratação',
        ]),
        'Corte + Hidratação',
      );
    });

    test('três ou mais usa +N', () {
      expect(
        ClientServiceHistoryServicesLabel.fromNames(const [
          'Corte',
          'Hidratação',
          'Escova',
          'Coloração',
        ]),
        AppStrings.clientServiceHistoryServicesAndMore(
          'Corte',
          'Hidratação',
          2,
        ),
      );
    });

    test('ausência de serviços', () {
      expect(
        ClientServiceHistoryServicesLabel.fromNames(const []),
        AppStrings.clientServiceHistoryServicesUnavailable,
      );
    });
  });

  group('ClientServiceHistoryDateFormatters', () {
    test('formata data completa em pt-BR compacto', () {
      expect(
        ClientServiceHistoryDateFormatters.formatItemDate(
          DateTime(2026, 7, 27),
        ),
        '27 JUL 2026',
      );
    });

    test('formata dia/mês', () {
      expect(
        ClientServiceHistoryDateFormatters.formatItemDayMonth(
          DateTime(2026, 6, 12),
        ),
        '12 JUN',
      );
    });
  });

  group('valores históricos', () {
    test('formata zero e positivo em pt-BR', () {
      expect(formatServicePrice(0), contains('0'));
      expect(formatServicePrice(120), contains('120'));
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
    clientId: 'client-1',
    occurredAt: occurredAt,
    kind: kind,
    servicesSummary: 'Corte',
    serviceNames: const ['Corte'],
  );
}
