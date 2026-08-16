import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_operational_summary.dart';

/// Como o dia da profissional deve ser interpretado no card HOJE.
enum HomeTodayCardState { freeDay, activeDay, finishedDay }

class HomeTodaySummaryPresentation {
  const HomeTodaySummaryPresentation({
    required this.state,
    required this.title,
    this.operationalLine,
    this.secondaryLine,
    this.warmLine,
    this.nextTimeLabel,
    this.showNewAppointmentCta = false,
  });

  final HomeTodayCardState state;
  final String title;
  final String? operationalLine;
  final String? secondaryLine;
  final String? warmLine;
  final String? nextTimeLabel;
  final bool showNewAppointmentCta;

  bool get isEmpty => state == HomeTodayCardState.freeDay;

  /// Anúncio único do card para leitores de tela. A linha acolhedora fica de
  /// fora porque é decorativa e não descreve o dia.
  String get semanticsLabel {
    final operational = operationalLine;
    final secondary = secondaryLine;
    final nextTime = nextTimeLabel;

    return [
      AppStrings.homeTodaySemanticsPrefix,
      title,
      if (operational != null) operational.replaceAll(' • ', ', '),
      ?secondary,
      ?nextTime,
    ].map(_withSentenceEnd).join(' ');
  }

  static String _withSentenceEnd(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('.') ||
        trimmed.endsWith('!') ||
        trimmed.endsWith('?')) {
      return trimmed;
    }
    return '$trimmed.';
  }
}

class HomeTodaySummaryFormatter {
  const HomeTodaySummaryFormatter._();

  static HomeTodaySummaryPresentation format({
    required int totalCount,
    required AgendaOperationalSummary summary,
    DateTime? nextUpcomingStartAt,
  }) {
    if (totalCount <= 0) {
      return const HomeTodaySummaryPresentation(
        state: HomeTodayCardState.freeDay,
        title: AppStrings.homeAgendaFreeToday,
        secondaryLine: AppStrings.homeEmptyDayDescription,
        warmLine: AppStrings.homeTodayFreeDayWarmLine,
        showNewAppointmentCta: true,
      );
    }

    final hasPending =
        summary.currentCount > 0 ||
        summary.upcomingCount > 0 ||
        summary.overdueCount > 0;

    if (!hasPending) {
      return _finishedDay(summary);
    }

    return HomeTodaySummaryPresentation(
      state: HomeTodayCardState.activeDay,
      title:
          '${_appointmentCountLabel(totalCount)} '
          '${AppStrings.homeTodayCountSuffix}',
      operationalLine: _activeOperationalLine(summary),
      nextTimeLabel: nextUpcomingStartAt == null
          ? null
          : '${AppStrings.homeTodayNextAtPrefix} '
                '${formatAppointmentClockTime(nextUpcomingStartAt)}',
    );
  }

  /// Dia sem pendências. Só é celebrado quando houve atendimento concluído;
  /// um dia apenas com cancelamentos recebe um título neutro.
  static HomeTodaySummaryPresentation _finishedDay(
    AgendaOperationalSummary summary,
  ) {
    final hasCompleted = summary.completedCount > 0;
    final parts = <String>[];

    if (hasCompleted) {
      parts.add(
        '${_appointmentCountLabel(summary.completedCount)} '
        '${_plural(summary.completedCount, AppStrings.homeSummaryCompletedSingular, AppStrings.homeSummaryCompletedPlural)}',
      );
    }

    if (summary.canceledCount > 0) {
      final canceledWord = _plural(
        summary.canceledCount,
        AppStrings.homeSummaryCanceledSingular,
        AppStrings.homeSummaryCanceledPlural,
      );
      parts.add(
        hasCompleted
            ? '${summary.canceledCount} $canceledWord'
            : '${_appointmentCountLabel(summary.canceledCount)} $canceledWord',
      );
    }

    return HomeTodaySummaryPresentation(
      state: HomeTodayCardState.finishedDay,
      title: hasCompleted
          ? AppStrings.homeTodayFinishedTitle
          : AppStrings.homeTodayNothingLeftTitle,
      operationalLine: parts.isEmpty ? null : parts.join(' • '),
      warmLine: hasCompleted ? AppStrings.homeTodayFinishedWarmLine : null,
    );
  }

  /// Overdue fica fora: quem comunica atraso é a seção Atenção.
  static String? _activeOperationalLine(AgendaOperationalSummary summary) {
    final parts = <String>[];

    if (summary.completedCount > 0) {
      parts.add(
        _countLabel(
          summary.completedCount,
          AppStrings.homeSummaryCompletedSingular,
          AppStrings.homeSummaryCompletedPlural,
        ),
      );
    }

    if (summary.currentCount > 0) {
      parts.add('${summary.currentCount} ${AppStrings.homeSummaryCurrent}');
    }

    if (summary.upcomingCount > 0) {
      parts.add(
        _countLabel(
          summary.upcomingCount,
          AppStrings.homeSummaryUpcomingSingular,
          AppStrings.homeSummaryUpcomingPlural,
        ),
      );
    }

    if (summary.canceledCount > 0) {
      parts.add(
        _countLabel(
          summary.canceledCount,
          AppStrings.homeSummaryCanceledSingular,
          AppStrings.homeSummaryCanceledPlural,
        ),
      );
    }

    return parts.isEmpty ? null : parts.join(' • ');
  }

  static String _appointmentCountLabel(int count) {
    return '$count '
        '${_plural(count, AppStrings.homeAppointmentSingular, AppStrings.homeAppointmentPlural)}';
  }

  static String _countLabel(int count, String singular, String plural) {
    return '$count ${_plural(count, singular, plural)}';
  }

  static String _plural(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
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
