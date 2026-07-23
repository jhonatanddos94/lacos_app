import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_display_sections.dart';
import 'package:lacos_app/features/agenda/application/organizers/agenda_display_organizer.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_appointment_scroll.dart';
import 'package:lacos_app/features/agenda/presentation/helpers/agenda_list_entries_builder.dart';
import 'package:lacos_app/features/agenda/presentation/mappers/agenda_appointment_display_mapper.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_empty_state.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_list_card.dart';
import 'package:lacos_app/features/agenda/presentation/widgets/agenda_section_header.dart';
import 'package:lacos_app/features/home/domain/entities/home_dashboard_data.dart';
import 'package:lacos_app/features/home/presentation/widgets/schedule_item.dart';

class AgendaAppointmentsList extends StatelessWidget {
  const AgendaAppointmentsList({
    required this.appointments,
    required this.selectedDay,
    this.scrollBottomPadding = 0,
    this.isPastDay = false,
    this.showEmptyState = true,
    this.wrapInCard = true,
    this.highlightedAppointmentId,
    this.scrollController,
    this.onAppointmentTap,
    super.key,
  });

  final List<AgendaAppointmentDisplay> appointments;
  final DateTime selectedDay;
  final double scrollBottomPadding;
  final bool isPastDay;
  final bool showEmptyState;
  final bool wrapInCard;
  final String? highlightedAppointmentId;
  final ScrollController? scrollController;
  final ValueChanged<AgendaAppointmentDisplay>? onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final sections = AgendaDisplayOrganizer.organize(appointments);

    if (sections.isEmpty) {
      if (!showEmptyState) {
        return const SizedBox.shrink();
      }

      return AgendaEmptyState(isPastDay: isPastDay);
    }

    final listView = AgendaScheduleListView(
      sections: sections,
      selectedDay: selectedDay,
      scrollBottomPadding: scrollBottomPadding,
      highlightedAppointmentId: highlightedAppointmentId,
      scrollController: scrollController,
      onAppointmentTap: onAppointmentTap,
    );

    if (!wrapInCard) {
      return listView;
    }

    return AgendaListCard(child: listView);
  }
}

class AgendaScheduleListView extends StatelessWidget {
  const AgendaScheduleListView({
    required this.sections,
    required this.selectedDay,
    this.scrollBottomPadding = 0,
    this.highlightedAppointmentId,
    this.scrollController,
    this.onAppointmentTap,
    super.key,
  });

  final AgendaDisplaySections sections;
  final DateTime selectedDay;
  final double scrollBottomPadding;
  final String? highlightedAppointmentId;
  final ScrollController? scrollController;
  final ValueChanged<AgendaAppointmentDisplay>? onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final entries = AgendaListEntriesBuilder.build(sections);
    final nextAppointmentId = _nextAppointmentId();

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(bottom: scrollBottomPadding),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final previousEntry = index > 0 ? entries[index - 1] : null;

        if (entry.type == AgendaListEntryType.sectionHeader) {
          return AgendaSectionHeader(title: entry.title!);
        }

        final appointment = entry.appointment!;
        final scheduleItem = AgendaAppointmentDisplayMapper.toScheduleItem(
          appointment,
          isNext: appointment.appointmentId == nextAppointmentId,
        );
        final isHighlighted =
            highlightedAppointmentId != null &&
            appointment.appointmentId == highlightedAppointmentId;
        final showDivider =
            previousEntry?.type == AgendaListEntryType.appointment;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDivider)
              Divider(
                height: AgendaAppointmentScroll.separatorHeight,
                thickness: 0.5,
                color: AppColors.divider.withValues(alpha: 0.55),
              ),
            ScheduleItem(
              appointment: scheduleItem,
              isHighlighted: isHighlighted,
              onTap: onAppointmentTap == null
                  ? null
                  : () => onAppointmentTap!(appointment),
            ),
          ],
        );
      },
    );
  }

  String? _nextAppointmentId() {
    final pendingAndConfirmed = [...sections.pending];
    final mapped = AgendaAppointmentDisplayMapper.toScheduleItems(
      pendingAndConfirmed,
      selectedDay,
    );

    for (var index = 0; index < pendingAndConfirmed.length; index++) {
      if (mapped[index].status == ScheduleStatus.next) {
        return pendingAndConfirmed[index].appointmentId;
      }
    }

    return null;
  }
}
