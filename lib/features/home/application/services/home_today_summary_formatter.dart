import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';

class HomeTodaySummaryPresentation {
  const HomeTodaySummaryPresentation({
    required this.isEmpty,
    required this.totalLabel,
    this.operationalLine,
    this.secondaryLine,
    this.showNewAppointmentCta = false,
  });

  final bool isEmpty;
  final String totalLabel;
  final String? operationalLine;
  final String? secondaryLine;
  final bool showNewAppointmentCta;
}

class HomeTodaySummaryFormatter {
  const HomeTodaySummaryFormatter._();

  static HomeTodaySummaryPresentation format({
    required int totalCount,
    required AgendaOperationalSummary summary,
  }) {
    if (totalCount <= 0) {
      return const HomeTodaySummaryPresentation(
        isEmpty: true,
        totalLabel: AppStrings.homeAgendaFreeToday,
        secondaryLine: AppStrings.homeEmptyDayDescription,
        showNewAppointmentCta: true,
      );
    }

    final totalLabel = totalCount == 1
        ? '1 ${AppStrings.homeAppointmentSingular}'
        : '$totalCount ${AppStrings.homeAppointmentPlural}';

    final operationalParts = <String>[];

    if (summary.completedCount > 0) {
      operationalParts.add(
        _countLabel(
          summary.completedCount,
          AppStrings.homeSummaryCompletedSingular,
          AppStrings.homeSummaryCompletedPlural,
        ),
      );
    }

    if (summary.currentCount > 0) {
      operationalParts.add(
        '${summary.currentCount} ${AppStrings.homeSummaryCurrent}',
      );
    }

    if (summary.upcomingCount > 0) {
      operationalParts.add(
        _countLabel(
          summary.upcomingCount,
          AppStrings.homeSummaryUpcomingSingular,
          AppStrings.homeSummaryUpcomingPlural,
        ),
      );
    }

    if (summary.canceledCount > 0) {
      operationalParts.add(
        _countLabel(
          summary.canceledCount,
          AppStrings.homeSummaryCanceledSingular,
          AppStrings.homeSummaryCanceledPlural,
        ),
      );
    }

    final operationalLine = operationalParts.isEmpty
        ? null
        : operationalParts.join(' • ');

    return HomeTodaySummaryPresentation(
      isEmpty: false,
      totalLabel: totalLabel,
      operationalLine: operationalLine,
    );
  }

  static String _countLabel(int count, String singular, String plural) {
    return count == 1 ? '1 $singular' : '$count $plural';
  }
}

class HomeAttentionFormatter {
  const HomeAttentionFormatter._();

  static String format(int overdueCount) {
    if (overdueCount <= 0) {
      return '';
    }

    if (overdueCount == 1) {
      return '1 ${AppStrings.homeAttentionWaitingSingular}';
    }

    return '$overdueCount ${AppStrings.homeAttentionWaitingPlural}';
  }
}
