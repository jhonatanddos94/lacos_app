import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/presentation/mappers/agenda_appointment_display_mapper.dart';
import 'package:lacos_app/features/appointments/application/models/created_appointment.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/create_appointment_bottom_sheet.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  static const _maxContentWidth = 560.0;
  static const _fabInset = AppSpacing.md;
  static const _fabClearance = 56.0 + _fabInset;

  late DateTime _selectedDay;
  var _isRefreshingAfterCreate = false;
  var _refreshAfterCreateFailed = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDay(DateTime.now());
  }

  DateTime get _normalizedSelectedDay => _normalizeDay(_selectedDay);

  AgendaDay get _selectedAgendaDay => AgendaDay.from(_selectedDay);

  List<DateTime> get _visibleDays {
    final start = _normalizedSelectedDay.subtract(const Duration(days: 3));
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = normalizeAppointmentDate(day));
  }

  Future<void> _refreshAppointmentsForDay(AgendaDay day) async {
    await Future.wait([
      ref.refresh(agendaAppointmentsDisplayProvider(day).future),
      ref.refresh(appointmentsByDayProvider(day).future),
    ]);
  }

  Future<void> _openNewAppointment() async {
    final createdAppointment = await showModalBottomSheet<CreatedAppointment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const CreateAppointmentBottomSheet(),
    );

    if (!mounted || createdAppointment == null) return;

    final createdDay = AgendaDay.from(createdAppointment.appointment.startAt);

    if (!isSameAppointmentDate(createdDay.toDateTime(), _normalizedSelectedDay)) {
      setState(() => _selectedDay = createdDay.toDateTime());
    }

    setState(() {
      _isRefreshingAfterCreate = true;
      _refreshAfterCreateFailed = false;
    });

    try {
      await _refreshAppointmentsForDay(createdDay);
      if (!mounted) return;

      setState(() => _isRefreshingAfterCreate = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.appointmentCreatedSuccess)),
      );
    } on Object {
      if (!mounted) return;

      setState(() {
        _isRefreshingAfterCreate = false;
        _refreshAfterCreateFailed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.agendaRefreshAfterCreateFailed),
        ),
      );
    }
  }

  Future<void> _retryRefreshAfterCreate() async {
    setState(() {
      _isRefreshingAfterCreate = true;
      _refreshAfterCreateFailed = false;
    });

    try {
      await _refreshAppointmentsForDay(_selectedAgendaDay);
      if (!mounted) return;

      setState(() {
        _isRefreshingAfterCreate = false;
        _refreshAfterCreateFailed = false;
      });
    } on Object {
      if (!mounted) return;

      setState(() {
        _isRefreshingAfterCreate = false;
        _refreshAfterCreateFailed = true;
      });
    }
  }

  void _retryLoadAppointments() {
    if (_refreshAfterCreateFailed) {
      unawaited(_retryRefreshAfterCreate());
      return;
    }

    unawaited(_refreshAppointmentsForDay(_selectedAgendaDay));
  }

  Widget _buildAppointmentsContent(
    AsyncValue<List<AgendaAppointmentDisplay>> appointmentsAsync,
  ) {
    if (_isRefreshingAfterCreate) {
      return _AgendaRefreshingAfterCreateState(
        appointments: appointmentsAsync.value ?? const [],
        selectedDay: _normalizedSelectedDay,
        bottomPadding: _fabClearance,
      );
    }

    if (_refreshAfterCreateFailed) {
      return _AgendaRefreshAfterCreateFailedState(
        appointments: appointmentsAsync.value ?? const [],
        selectedDay: _normalizedSelectedDay,
        bottomPadding: _fabClearance,
        onRetry: () => unawaited(_retryRefreshAfterCreate()),
      );
    }

    return appointmentsAsync.when(
      loading: () => const _AgendaLoadingState(),
      error: (error, _) => _AgendaErrorState(
        message: _resolveAgendaErrorMessage(error),
        onRetry: _retryLoadAppointments,
      ),
      data: (appointments) => _AgendaAppointmentsList(
        appointments: appointments,
        selectedDay: _normalizedSelectedDay,
        bottomPadding: _fabClearance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(
      agendaAppointmentsDisplayProvider(_selectedAgendaDay),
    );

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: _AgendaHeader(
                      selectedDay: _normalizedSelectedDay,
                      appointments: appointmentsAsync.value,
                      isLoading: _isRefreshingAfterCreate ||
                          (appointmentsAsync.isLoading &&
                              !appointmentsAsync.hasValue),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.sm),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: _AgendaDaySelector(
                      days: _visibleDays,
                      selectedDay: _normalizedSelectedDay,
                      onDaySelected: _selectDay,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: _buildAppointmentsContent(appointmentsAsync),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: _fabInset,
            bottom: _fabInset,
            child: FloatingActionButton.extended(
              heroTag: 'agenda_fab',
              onPressed: _openNewAppointment,
              backgroundColor: AppColors.lacosPurple,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo'),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _normalizeDay(DateTime day) => normalizeAppointmentDate(day);
}

String _resolveAgendaErrorMessage(Object error) {
  return switch (error) {
    FormatException(message: final message) when message.isNotEmpty => message,
    StateError(message: final message) => message,
    _ => AppStrings.temporaryLoadError,
  };
}

class _AgendaAppointmentsList extends StatelessWidget {
  const _AgendaAppointmentsList({
    required this.appointments,
    required this.selectedDay,
    required this.bottomPadding,
    this.showEmptyState = true,
    this.wrapInCard = true,
  });

  final List<AgendaAppointmentDisplay> appointments;
  final DateTime selectedDay;
  final double bottomPadding;
  final bool showEmptyState;
  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    final scheduleItems = AgendaAppointmentDisplayMapper.toScheduleItems(
      appointments,
      selectedDay,
    );

    if (scheduleItems.isEmpty) {
      if (!showEmptyState) {
        return const SizedBox.shrink();
      }

      return _AgendaEmptyState(bottomPadding: bottomPadding);
    }

    final listView = _AgendaScheduleListView(scheduleItems: scheduleItems);

    if (!wrapInCard) {
      return listView;
    }

    return _AgendaListCard(
      bottomPadding: bottomPadding,
      child: listView,
    );
  }
}

class _AgendaScheduleListView extends StatelessWidget {
  const _AgendaScheduleListView({required this.scheduleItems});

  final List<TodayScheduleAppointment> scheduleItems;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: scheduleItems.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.divider.withValues(alpha: 0.55),
      ),
      itemBuilder: (context, index) {
        return ScheduleItem(appointment: scheduleItems[index]);
      },
    );
  }
}

class _AgendaListCard extends StatelessWidget {
  const _AgendaListCard({
    required this.child,
    required this.bottomPadding,
  });

  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ClipRRect(
        borderRadius: AppRadius.borderMd,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMd,
            boxShadow: AppShadows.level1,
            border: Border.all(color: AppColors.divider),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AgendaRefreshingAfterCreateState extends StatelessWidget {
  const _AgendaRefreshingAfterCreateState({
    required this.appointments,
    required this.selectedDay,
    required this.bottomPadding,
  });

  final List<AgendaAppointmentDisplay> appointments;
  final DateTime selectedDay;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AgendaListCard(
      bottomPadding: bottomPadding,
      child: appointments.isEmpty
          ? _AgendaRefreshingBanner(theme: theme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AgendaRefreshingBanner(theme: theme),
                Expanded(
                  child: _AgendaAppointmentsList(
                    appointments: appointments,
                    selectedDay: selectedDay,
                    bottomPadding: 0,
                    showEmptyState: false,
                    wrapInCard: false,
                  ),
                ),
              ],
            ),
    );
  }
}

class _AgendaRefreshingBanner extends StatelessWidget {
  const _AgendaRefreshingBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            AppStrings.agendaRefreshingAfterCreate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaRefreshAfterCreateFailedState extends StatelessWidget {
  const _AgendaRefreshAfterCreateFailedState({
    required this.appointments,
    required this.selectedDay,
    required this.bottomPadding,
    required this.onRetry,
  });

  final List<AgendaAppointmentDisplay> appointments;
  final DateTime selectedDay;
  final double bottomPadding;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AgendaListCard(
      bottomPadding: bottomPadding,
      child: appointments.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
              ),
              child: _AgendaRefreshAfterCreateFailedMessage(
                theme: theme,
                onRetry: onRetry,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: _AgendaRefreshAfterCreateFailedMessage(
                    theme: theme,
                    onRetry: onRetry,
                  ),
                ),
                Expanded(
                  child: _AgendaAppointmentsList(
                    appointments: appointments,
                    selectedDay: selectedDay,
                    bottomPadding: 0,
                    showEmptyState: false,
                    wrapInCard: false,
                  ),
                ),
              ],
            ),
    );
  }
}

class _AgendaRefreshAfterCreateFailedMessage extends StatelessWidget {
  const _AgendaRefreshAfterCreateFailedMessage({
    required this.theme,
    required this.onRetry,
  });

  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppStrings.agendaRefreshAfterCreateFailed,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        TextButton(
          onPressed: onRetry,
          child: const Text(AppStrings.agendaRetryUpdate),
        ),
      ],
    );
  }
}

class _AgendaLoadingState extends StatelessWidget {
  const _AgendaLoadingState();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMd,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.level1,
          border: Border.all(color: AppColors.divider),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaErrorState extends StatelessWidget {
  const _AgendaErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: AppRadius.borderMd,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.level1,
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: AppStrings.tryAgain,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaEmptyState extends StatelessWidget {
  const _AgendaEmptyState({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: AppRadius.borderMd,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.level1,
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg + bottomPadding,
          ),
          child: Center(
            child: Text(
              AppStrings.agendaEmptyDay,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({
    required this.selectedDay,
    required this.appointments,
    required this.isLoading,
  });

  final DateTime selectedDay;
  final List<AgendaAppointmentDisplay>? appointments;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = _isSameDay(selectedDay, today);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Agenda',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.purple700,
                    size: AppIconSizes.md,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatAgendaDateLine(selectedDay, isToday: isToday),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _buildSummary(isToday: isToday),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _HeaderIconButton(
          icon: Icons.tune_rounded,
          onPressed: () {},
        ),
      ],
    );
  }

  String _buildSummary({required bool isToday}) {
    if (isLoading) {
      return AppStrings.loading;
    }

    final loadedAppointments = appointments;
    if (loadedAppointments == null) {
      return isToday ? 'Nenhum atendimento hoje' : 'Nenhum atendimento';
    }

    if (loadedAppointments.isEmpty) {
      return isToday ? 'Nenhum atendimento hoje' : 'Nenhum atendimento';
    }

    final countLabel = loadedAppointments.length == 1
        ? '1 atendimento'
        : '${loadedAppointments.length} atendimentos';
    final nextTime = AgendaAppointmentDisplayMapper.nextStartTime(
      loadedAppointments,
      selectedDay,
    );

    if (nextTime == null) {
      return countLabel;
    }

    return '$countLabel • Próximo às $nextTime';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderSm,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.purple700,
        iconSize: AppIconSizes.md,
        tooltip: '',
      ),
    );
  }
}

class _AgendaDaySelector extends StatelessWidget {
  const _AgendaDaySelector({
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xxs),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, selectedDay);
          final isToday = _isSameDay(day, DateTime.now());

          return _AgendaDayChip(
            day: day,
            isSelected: isSelected,
            isToday: isToday,
            onTap: () => onDaySelected(day),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _AgendaDayChip extends StatelessWidget {
  const _AgendaDayChip({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekday = _weekdayLabel(day.weekday);
    final backgroundColor = isSelected ? AppColors.lacosPurple : AppColors.surface;
    final borderColor = isSelected ? AppColors.lacosPurple : AppColors.divider;
    final textColor = isSelected ? AppColors.onPrimary : AppColors.graphite;
    final subtitleColor = isSelected
        ? AppColors.onPrimary.withValues(alpha: 0.88)
        : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Ink(
          width: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: borderColor),
            boxShadow: isSelected ? AppShadows.level1 : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                '${day.day}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: AppSpacing.xxxs),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.onPrimary : AppColors.lacosPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Seg',
      DateTime.tuesday => 'Ter',
      DateTime.wednesday => 'Qua',
      DateTime.thursday => 'Qui',
      DateTime.friday => 'Sex',
      DateTime.saturday => 'Sáb',
      DateTime.sunday => 'Dom',
      _ => '',
    };
  }
}

String _formatAgendaDateLine(DateTime day, {required bool isToday}) {
  final weekday = _fullWeekdayName(day.weekday);
  final dayNumber = day.day.toString().padLeft(2, '0');
  final month = _fullMonthName(day.month);
  final formattedDate = '$weekday, $dayNumber de $month';

  if (isToday) {
    return 'Hoje • $formattedDate';
  }

  return formattedDate;
}

String _fullWeekdayName(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Segunda-feira',
    DateTime.tuesday => 'Terça-feira',
    DateTime.wednesday => 'Quarta-feira',
    DateTime.thursday => 'Quinta-feira',
    DateTime.friday => 'Sexta-feira',
    DateTime.saturday => 'Sábado',
    DateTime.sunday => 'Domingo',
    _ => '',
  };
}

String _fullMonthName(int month) {
  return switch (month) {
    1 => 'Janeiro',
    2 => 'Fevereiro',
    3 => 'Março',
    4 => 'Abril',
    5 => 'Maio',
    6 => 'Junho',
    7 => 'Julho',
    8 => 'Agosto',
    9 => 'Setembro',
    10 => 'Outubro',
    11 => 'Novembro',
    12 => 'Dezembro',
    _ => '',
  };
}
