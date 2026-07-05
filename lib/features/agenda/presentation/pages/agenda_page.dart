import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  static const _maxContentWidth = 560.0;
  static const _fabInset = AppSpacing.md;
  static const _fabClearance = 56.0 + _fabInset;

  static const _mockAppointments = [
    TodayScheduleAppointment(
      startTime: '09:00',
      endTime: '10:00',
      clientName: 'Juliana Mendes',
      serviceName: 'Coloração',
      status: ScheduleStatus.completed,
    ),
    TodayScheduleAppointment(
      startTime: '11:00',
      endTime: '12:30',
      clientName: 'Marina Costa',
      serviceName: 'Mechas + Tonalização',
      status: ScheduleStatus.completed,
    ),
    TodayScheduleAppointment(
      startTime: '14:30',
      endTime: '15:30',
      clientName: 'Ana Paula Silva',
      serviceName: 'Corte e Escova',
      status: ScheduleStatus.next,
    ),
  ];

  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  List<DateTime> get _visibleDays {
    final start = _selectedDay.subtract(const Duration(days: 3));
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
  }

  void _openNewAppointment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Novo agendamento em breve.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      selectedDay: _selectedDay,
                      appointments: _mockAppointments,
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
                      selectedDay: _selectedDay,
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
                      child: ClipRRect(
                        borderRadius: AppRadius.borderMd,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.borderMd,
                            boxShadow: AppShadows.level1,
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.only(
                              bottom: _fabClearance,
                            ),
                            itemCount: _mockAppointments.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.divider.withValues(alpha: 0.55),
                            ),
                            itemBuilder: (context, index) {
                              return ScheduleItem(
                                appointment: _mockAppointments[index],
                              );
                            },
                          ),
                        ),
                      ),
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
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({
    required this.selectedDay,
    required this.appointments,
  });

  final DateTime selectedDay;
  final List<TodayScheduleAppointment> appointments;

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
                _formatDaySummary(appointments, isToday: isToday),
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

String _formatDaySummary(
  List<TodayScheduleAppointment> appointments, {
  required bool isToday,
}) {
  if (appointments.isEmpty) {
    return isToday ? 'Nenhum atendimento hoje' : 'Nenhum atendimento';
  }

  final countLabel =
      appointments.length == 1 ? '1 atendimento' : '${appointments.length} atendimentos';
  final nextTime = _nextAppointmentTime(appointments);

  if (nextTime == null) {
    return countLabel;
  }

  return '$countLabel • Próximo às $nextTime';
}

String? _nextAppointmentTime(List<TodayScheduleAppointment> appointments) {
  final upcoming = appointments.where(
    (appointment) => appointment.status != ScheduleStatus.completed,
  );

  if (upcoming.isEmpty) {
    return null;
  }

  return upcoming.first.startTime;
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
