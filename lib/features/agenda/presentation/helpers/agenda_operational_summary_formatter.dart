import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';

String formatAgendaOperationalSummaryLine(AgendaOperationalSummary summary) {
  if (!summary.hasActiveOperationalItems) {
    return AppStrings.agendaOperationalSummaryNone;
  }

  final parts = <String>[];

  if (summary.overdueCount > 0) {
    parts.add(
      _countLabel(
        summary.overdueCount,
        AppStrings.agendaOperationalSummaryOverdue,
      ),
    );
  }

  if (summary.currentCount > 0) {
    parts.add(
      _countLabel(
        summary.currentCount,
        AppStrings.agendaOperationalSummaryCurrent,
      ),
    );
  }

  if (summary.upcomingCount > 0) {
    parts.add(
      _countLabel(
        summary.upcomingCount,
        AppStrings.agendaOperationalSummaryUpcoming,
      ),
    );
  }

  return parts.join(' • ');
}

String _countLabel(int count, String label) {
  return '$count $label';
}
