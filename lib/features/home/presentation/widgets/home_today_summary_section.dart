import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/theme/app_typography.dart';
import 'package:lacos_app/features/home/application/services/home_today_summary_formatter.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class HomeTodaySummarySection extends StatelessWidget {
  const HomeTodaySummarySection({
    required this.presentation,
    required this.onOpenAgenda,
    required this.onNewAppointment,
    super.key,
  });

  static const sectionKey = Key('home-today-summary');
  static const newAppointmentCtaKey = Key('home-today-summary-new-appointment');
  static const stateIconKey = Key('home-today-summary-state-icon');
  static const nextTimePillKey = Key('home-today-summary-next-time');
  static const todayBadgeKey = Key('home-today-summary-badge');
  static const completedCheckKey = Key('home-today-completed-check');
  static const statusIndicatorsKey = Key('home-today-status-indicators');

  static const illustrationSize = AppSpacing.xxl;
  static const compactIllustrationSize = AppSpacing.xl;
  static const illustrationIconSize = AppIconSizes.lg;
  static const compactIllustrationIconSize = AppIconSizes.md;

  final HomeTodaySummaryPresentation presentation;
  final VoidCallback onOpenAgenda;
  final VoidCallback onNewAppointment;

  @override
  Widget build(BuildContext context) {
    final isEmpty = presentation.isEmpty;

    final card = Material(
      key: sectionKey,
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: isEmpty ? null : onOpenAgenda,
        borderRadius: AppRadius.borderMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            boxShadow: AppShadows.level1,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                label: presentation.semanticsLabel,
                child: ExcludeSemantics(child: _Content(presentation)),
              ),
              if (presentation.showNewAppointmentCta) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    key: newAppointmentCtaKey,
                    label: AppStrings.homeNewAppointmentCta,
                    variant: AppButtonVariant.text,
                    onPressed: onNewAppointment,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isEmpty) {
      return card;
    }

    return Semantics(
      button: true,
      label: AppStrings.homeOpenTodayAgendaLabel,
      child: card,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.presentation);

  final HomeTodaySummaryPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTypography.subtitle().copyWith(
      color: AppColors.graphite,
      fontWeight: FontWeight.w800,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final textScale = textScaler.scale(1);
        final scaledTitleSize = textScaler.scale(titleStyle.fontSize ?? 18);
        final badgeWidth = textScaler.scale(48);
        final minContentWidth = scaledTitleSize * 7;
        final availableAfterBadge =
            constraints.maxWidth - badgeWidth - AppSpacing.xs;

        final useFullIllustration =
            constraints.maxWidth >= 300 && textScale <= 1.3;
        final preferredSize = useFullIllustration
            ? HomeTodaySummarySection.illustrationSize
            : HomeTodaySummarySection.compactIllustrationSize;
        final preferredIconSize = useFullIllustration
            ? HomeTodaySummarySection.illustrationIconSize
            : HomeTodaySummarySection.compactIllustrationIconSize;

        final fullFits =
            availableAfterBadge -
                (HomeTodaySummarySection.illustrationSize + AppSpacing.xxs) >=
            minContentWidth;
        final compactFits =
            availableAfterBadge -
                (HomeTodaySummarySection.compactIllustrationSize +
                    AppSpacing.xxs) >=
            minContentWidth;

        final double? illustrationSize;
        final double illustrationIconSize;
        if (useFullIllustration && fullFits) {
          illustrationSize = preferredSize;
          illustrationIconSize = preferredIconSize;
        } else if (compactFits) {
          illustrationSize = HomeTodaySummarySection.compactIllustrationSize;
          illustrationIconSize =
              HomeTodaySummarySection.compactIllustrationIconSize;
        } else {
          illustrationSize = null;
          illustrationIconSize = 0;
        }

        final showSparkles =
            illustrationSize != null &&
            useFullIllustration &&
            fullFits &&
            textScale <= 1.3;
        final showTitleAccent = illustrationSize != null && textScale <= 1.3;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxxs),
              child: _TodayBadge(),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _StateCopy(
                presentation: presentation,
                titleStyle: titleStyle,
                showTitleAccent: showTitleAccent,
              ),
            ),
            if (illustrationSize != null) ...[
              const SizedBox(width: AppSpacing.xxs),
              _TodayStateIllustration(
                state: presentation.state,
                showSparkles: showSparkles,
                size: illustrationSize,
                iconSize: illustrationIconSize,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StateCopy extends StatelessWidget {
  const _StateCopy({
    required this.presentation,
    required this.titleStyle,
    required this.showTitleAccent,
  });

  final HomeTodaySummaryPresentation presentation;
  final TextStyle titleStyle;
  final bool showTitleAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operationalStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.graphite,
      fontWeight: FontWeight.w600,
    );
    final descriptionStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleWithAccent(
          title: presentation.title,
          style: titleStyle,
          state: presentation.state,
          showAccent: showTitleAccent,
        ),
        ..._buildBody(
          operationalStyle: operationalStyle,
          descriptionStyle: descriptionStyle,
        ),
      ],
    );
  }

  List<Widget> _buildBody({
    required TextStyle? operationalStyle,
    required TextStyle? descriptionStyle,
  }) {
    final operationalLine = presentation.operationalLine;
    final secondaryLine = presentation.secondaryLine;
    final warmLine = presentation.warmLine;
    final nextTimeLabel = presentation.nextTimeLabel;
    final parts = _statusParts(operationalLine);

    return [
      if (parts.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xxs),
        _StatusRow(
          parts: parts,
          style: operationalStyle,
          emphasizeCompletedCheck:
              presentation.state == HomeTodayCardState.finishedDay,
        ),
      ],
      if (secondaryLine != null) ...[
        const SizedBox(height: AppSpacing.xxs),
        Text(secondaryLine, style: descriptionStyle),
      ],
      if (warmLine != null) ...[
        const SizedBox(height: AppSpacing.xxs),
        _WarmLine(text: warmLine, style: descriptionStyle),
      ],
      if (nextTimeLabel != null) ...[
        const SizedBox(height: AppSpacing.xs),
        _NextTimePill(nextTimeLabel),
      ],
    ];
  }
}

class _TitleWithAccent extends StatelessWidget {
  const _TitleWithAccent({
    required this.title,
    required this.style,
    required this.state,
    required this.showAccent,
  });

  final String title;
  final TextStyle style;
  final HomeTodayCardState state;
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    final accent = switch (state) {
      HomeTodayCardState.finishedDay => const _TitleAccent(
        icon: Icons.auto_awesome,
        color: AppColors.warmAmber,
        size: 14,
      ),
      HomeTodayCardState.freeDay => const _TitleAccent(
        icon: Icons.eco_outlined,
        color: AppColors.softGreen,
        size: 14,
      ),
      HomeTodayCardState.activeDay => null,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: Text(title, style: style)),
        if (showAccent && accent != null) ...[
          const SizedBox(width: AppSpacing.xxxs),
          Icon(accent.icon, size: accent.size, color: accent.color),
        ],
      ],
    );
  }
}

class _TitleAccent {
  const _TitleAccent({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;
}

class _WarmLine extends StatelessWidget {
  const _WarmLine({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: Text(text, style: style)),
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.xxxs, top: 1),
          child: Icon(
            Icons.favorite_border_rounded,
            size: 12,
            color: AppColors.purple400,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.parts,
    required this.style,
    required this.emphasizeCompletedCheck,
  });

  final List<String> parts;
  final TextStyle? style;
  final bool emphasizeCompletedCheck;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          key: HomeTodaySummarySection.statusIndicatorsKey,
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var index = 0; index < parts.length; index++) ...[
              if (index > 0)
                Container(width: 1, height: 12, color: AppColors.divider),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: _StatusItem(
                  label: parts[index],
                  style: style,
                  showCompletedCheck: emphasizeCompletedCheck,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.label,
    required this.style,
    required this.showCompletedCheck,
  });

  final String label;
  final TextStyle? style;
  final bool showCompletedCheck;

  @override
  Widget build(BuildContext context) {
    final kind = _statusKind(label);
    final indicator = kind == _StatusKind.completed && showCompletedCheck
        ? const _CompletedCheck()
        : _StatusDot(color: _dotColor(kind));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        indicator,
        const SizedBox(width: AppSpacing.xxxs),
        Flexible(child: Text(label, style: style)),
      ],
    );
  }
}

class _CompletedCheck extends StatelessWidget {
  const _CompletedCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: HomeTodaySummarySection.completedCheckKey,
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: AppColors.lacosPurple,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 11,
        color: AppColors.onPrimary,
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: HomeTodaySummarySection.todayBadgeKey,
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: AppRadius.borderXs,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxs,
          vertical: AppSpacing.xxxs,
        ),
        child: Text(
          AppStrings.homeTodayTitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.purple700,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _NextTimePill extends StatelessWidget {
  const _NextTimePill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        key: HomeTodaySummarySection.nextTimePillKey,
        decoration: BoxDecoration(
          color: AppColors.purple50,
          borderRadius: AppRadius.borderXs,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xxxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.purple700,
              ),
              const SizedBox(width: AppSpacing.xxxs),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.purple700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayStateIllustration extends StatelessWidget {
  const _TodayStateIllustration({
    required this.state,
    required this.showSparkles,
    required this.size,
    required this.iconSize,
  });

  final HomeTodayCardState state;
  final bool showSparkles;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      HomeTodayCardState.freeDay => Icons.local_cafe_outlined,
      HomeTodayCardState.activeDay => Icons.calendar_month_outlined,
      HomeTodayCardState.finishedDay => Icons.event_available_outlined,
    };

    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              key: HomeTodaySummarySection.stateIconKey,
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.purple50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.purple700, size: iconSize),
            ),
            if (showSparkles) ...[
              const Positioned(
                top: -2,
                right: -2,
                child: _TodaySparkle(size: 10, color: AppColors.purple400),
              ),
              const Positioned(
                bottom: 2,
                left: -4,
                child: _TodaySparkle(size: 8, color: AppColors.purple200),
              ),
              const Positioned(
                top: 22,
                right: -6,
                child: _TodaySparkle(size: 7, color: AppColors.purple200),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TodaySparkle extends StatelessWidget {
  const _TodaySparkle({this.size = 10, this.color = AppColors.purple200});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, size: size, color: color);
  }
}

enum _StatusKind { completed, current, upcoming, canceled, other }

List<String> _statusParts(String? operationalLine) {
  if (operationalLine == null || operationalLine.isEmpty) {
    return const [];
  }
  return operationalLine
      .split(' • ')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}

_StatusKind _statusKind(String label) {
  if (label.contains(AppStrings.homeSummaryCompletedSingular)) {
    return _StatusKind.completed;
  }
  if (label.contains(AppStrings.homeSummaryCurrent)) {
    return _StatusKind.current;
  }
  if (label.contains(AppStrings.homeSummaryUpcomingSingular)) {
    return _StatusKind.upcoming;
  }
  if (label.contains(AppStrings.homeSummaryCanceledSingular)) {
    return _StatusKind.canceled;
  }
  return _StatusKind.other;
}

Color _dotColor(_StatusKind kind) {
  return switch (kind) {
    _StatusKind.completed => AppColors.lacosPurple,
    _StatusKind.current => AppColors.purple700,
    _StatusKind.upcoming => AppColors.warmAmber,
    _StatusKind.canceled => AppColors.textSecondary,
    _StatusKind.other => AppColors.purple300,
  };
}
