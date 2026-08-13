import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_item.dart';
import 'package:lacos_app/features/clients/application/models/client_service_history_month_group.dart';

/// Agrupa itens de histórico por mês/ano (mais recente primeiro).
class ClientServiceHistoryGrouper {
  const ClientServiceHistoryGrouper._();

  static const _monthLabels = [
    'JANEIRO',
    'FEVEREIRO',
    'MARÇO',
    'ABRIL',
    'MAIO',
    'JUNHO',
    'JULHO',
    'AGOSTO',
    'SETEMBRO',
    'OUTUBRO',
    'NOVEMBRO',
    'DEZEMBRO',
  ];

  static List<ClientServiceHistoryMonthGroup> groupByMonth(
    List<ClientServiceHistoryItem> items,
  ) {
    if (items.isEmpty) {
      return const [];
    }

    final sorted = [...items]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final groups = <ClientServiceHistoryMonthGroup>[];
    int? currentYear;
    int? currentMonth;
    var bucket = <ClientServiceHistoryItem>[];

    void flush() {
      final year = currentYear;
      final month = currentMonth;
      if (year == null || month == null || bucket.isEmpty) {
        return;
      }

      groups.add(
        ClientServiceHistoryMonthGroup(
          year: year,
          month: month,
          label: monthYearLabel(year, month),
          items: List<ClientServiceHistoryItem>.unmodifiable(bucket),
        ),
      );
      bucket = <ClientServiceHistoryItem>[];
    }

    for (final item in sorted) {
      final local = item.occurredAt.toLocal();
      if (currentYear != local.year || currentMonth != local.month) {
        flush();
        currentYear = local.year;
        currentMonth = local.month;
      }
      bucket.add(item);
    }
    flush();

    return List<ClientServiceHistoryMonthGroup>.unmodifiable(groups);
  }

  static String monthYearLabel(int year, int month) {
    if (month < 1 || month > 12) {
      return '$year';
    }
    return '${_monthLabels[month - 1]} $year';
  }
}

/// Monta o label de serviços do histórico (até 2 nomes + “+N”).
class ClientServiceHistoryServicesLabel {
  const ClientServiceHistoryServicesLabel._();

  static String fromNames(List<String> names) {
    final cleaned = names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    if (cleaned.isEmpty) {
      return AppStrings.clientServiceHistoryServicesUnavailable;
    }

    if (cleaned.length == 1) {
      return cleaned.first;
    }

    if (cleaned.length == 2) {
      return '${cleaned[0]} + ${cleaned[1]}';
    }

    return AppStrings.clientServiceHistoryServicesAndMore(
      cleaned[0],
      cleaned[1],
      cleaned.length - 2,
    );
  }
}

/// Formatação de datas do histórico (pt-BR compacto).
class ClientServiceHistoryDateFormatters {
  const ClientServiceHistoryDateFormatters._();

  static const _shortMonths = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];

  /// Ex.: `27 JUL 2026`
  static String formatItemDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _shortMonths[local.month - 1];
    return '$day $month ${local.year}';
  }

  /// Ex.: `27 JUL`
  static String formatItemDayMonth(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _shortMonths[local.month - 1];
    return '$day $month';
  }
}
