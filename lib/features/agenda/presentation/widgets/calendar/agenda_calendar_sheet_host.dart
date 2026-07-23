import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_calendar_view.dart';
import 'package:lacos_app/features/agenda/application/providers/agenda_providers.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_bottom_sheet.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/calendar/agenda_calendar_month_grid.dart';

Future<DateTime?> showAgendaCalendarSheet({
  required BuildContext context,
  required DateTime initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) {
      return AgendaCalendarSheetHost(
        initialDate: normalizeCalendarDay(initialDate),
      );
    },
  );
}

class AgendaCalendarSheetHost extends ConsumerStatefulWidget {
  const AgendaCalendarSheetHost({required this.initialDate, super.key});

  final DateTime initialDate;

  @override
  ConsumerState<AgendaCalendarSheetHost> createState() =>
      _AgendaCalendarSheetHostState();
}

class _AgendaCalendarSheetHostState
    extends ConsumerState<AgendaCalendarSheetHost> {
  late AgendaCalendarView _displayedView;

  @override
  void initState() {
    super.initState();
    _displayedView = AgendaCalendarView(
      year: widget.initialDate.year,
      month: widget.initialDate.month,
    );
  }

  void _onDisplayedMonthChanged(AgendaCalendarMonthGrid month) {
    final nextView = AgendaCalendarView(year: month.year, month: month.month);
    if (nextView == _displayedView) return;

    setState(() => _displayedView = nextView);
  }

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(
      agendaCalendarAppointmentDaysProvider(_displayedView),
    );

    return AgendaCalendarBottomSheet(
      initialDate: widget.initialDate,
      daysWithAppointments: daysAsync.value ?? const {},
      onDisplayedMonthChanged: _onDisplayedMonthChanged,
    );
  }
}
