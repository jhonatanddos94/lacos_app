import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_appointment_scroll.dart';
import 'package:lacos_app/features/agenda/presentation/mappers/agenda_appointment_display_mapper.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_empty_state.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_list_card.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';

class AgendaAppointmentsList extends StatelessWidget {
  const AgendaAppointmentsList({
    required this.appointments,
    required this.selectedDay,
    required this.bottomPadding,
    this.showEmptyState = true,
    this.wrapInCard = true,
    this.highlightedAppointmentId,
    this.scrollController,
    this.onAppointmentTap,
    super.key,
  });

  final List<AgendaAppointmentDisplay> appointments;
  final DateTime selectedDay;
  final double bottomPadding;
  final bool showEmptyState;
  final bool wrapInCard;
  final String? highlightedAppointmentId;
  final ScrollController? scrollController;
  final ValueChanged<AgendaAppointmentDisplay>? onAppointmentTap;

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

      return AgendaEmptyState(bottomPadding: bottomPadding);
    }

    final listView = AgendaScheduleListView(
      appointments: appointments,
      selectedDay: selectedDay,
      highlightedAppointmentId: highlightedAppointmentId,
      scrollController: scrollController,
      onAppointmentTap: onAppointmentTap,
    );

    if (!wrapInCard) {
      return listView;
    }

    return AgendaListCard(
      bottomPadding: bottomPadding,
      child: listView,
    );
  }
}

class AgendaScheduleListView extends StatelessWidget {
  const AgendaScheduleListView({
    required this.appointments,
    required this.selectedDay,
    this.highlightedAppointmentId,
    this.scrollController,
    this.onAppointmentTap,
    super.key,
  });

  final List<AgendaAppointmentDisplay> appointments;
  final DateTime selectedDay;
  final String? highlightedAppointmentId;
  final ScrollController? scrollController;
  final ValueChanged<AgendaAppointmentDisplay>? onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final scheduleItems = AgendaAppointmentDisplayMapper.toScheduleItems(
      appointments,
      selectedDay,
    );

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: scheduleItems.length,
      separatorBuilder: (_, _) => Divider(
        height: AgendaAppointmentScroll.separatorHeight,
        thickness: 0.5,
        color: AppColors.divider.withValues(alpha: 0.55),
      ),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final isHighlighted =
            highlightedAppointmentId != null &&
            appointment.appointmentId == highlightedAppointmentId;

        return ScheduleItem(
          appointment: scheduleItems[index],
          isHighlighted: isHighlighted,
          onTap: onAppointmentTap == null
              ? null
              : () => onAppointmentTap!(appointment),
        );
      },
    );
  }
}
