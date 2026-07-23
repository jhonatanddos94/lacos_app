import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_display_sections.dart';

enum AgendaListEntryType { sectionHeader, appointment }

class AgendaListEntry {
  const AgendaListEntry._({required this.type, this.title, this.appointment});

  const AgendaListEntry.sectionHeader(String title)
    : this._(type: AgendaListEntryType.sectionHeader, title: title);

  const AgendaListEntry.appointment(AgendaAppointmentDisplay appointment)
    : this._(type: AgendaListEntryType.appointment, appointment: appointment);

  final AgendaListEntryType type;
  final String? title;
  final AgendaAppointmentDisplay? appointment;
}

class AgendaListEntriesBuilder {
  const AgendaListEntriesBuilder._();

  static List<AgendaListEntry> build(AgendaDisplaySections sections) {
    final entries = <AgendaListEntry>[];

    if (sections.showPendingHeader) {
      entries.add(
        AgendaListEntry.sectionHeader(
          formatAgendaSectionTitle(
            baseTitle: AppStrings.agendaSectionPending,
            count: sections.pending.length,
          ),
        ),
      );
    }
    entries.addAll(sections.pending.map(AgendaListEntry.appointment));

    if (sections.hasCompletedSection) {
      entries.add(
        AgendaListEntry.sectionHeader(
          formatAgendaSectionTitle(
            baseTitle: AppStrings.agendaSectionCompleted,
            count: sections.completed.length,
          ),
        ),
      );
      entries.addAll(sections.completed.map(AgendaListEntry.appointment));
    }

    if (sections.hasCanceledSection) {
      entries.add(
        AgendaListEntry.sectionHeader(
          formatAgendaSectionTitle(
            baseTitle: AppStrings.agendaSectionCanceled,
            count: sections.canceled.length,
          ),
        ),
      );
      entries.addAll(sections.canceled.map(AgendaListEntry.appointment));
    }

    return entries;
  }

  static int? indexForAppointmentId(
    List<AgendaListEntry> entries,
    String appointmentId,
  ) {
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (entry.type == AgendaListEntryType.appointment &&
          entry.appointment!.appointmentId == appointmentId) {
        return index;
      }
    }

    return null;
  }
}
