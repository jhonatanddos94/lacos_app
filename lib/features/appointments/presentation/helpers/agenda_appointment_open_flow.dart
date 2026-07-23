import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_preparation_eligibility.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_details_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_preparation_sheet_host.dart';
import 'package:lacos_app/features/appointments/presentation/models/appointment_preparation_action.dart';

Future<Object?> openAgendaAppointmentFlow({
  required BuildContext context,
  required WidgetRef ref,
  required AgendaAppointmentDisplay appointment,
  DateTime? now,
}) async {
  final referenceNow = now ?? DateTime.now();

  if (AppointmentPreparationEligibility.isEligible(
    status: appointment.status,
    startAt: appointment.startAt,
    endAt: appointment.endAt,
    now: referenceNow,
  )) {
    final preparationAction = await showAppointmentPreparationBottomSheet(
      context: context,
      ref: ref,
      appointment: appointment,
    );

    if (!context.mounted) {
      return null;
    }

    if (preparationAction == AppointmentPreparationAction.dismiss) {
      return null;
    }
  }

  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) => AppointmentDetailsBottomSheet(
      appointmentId: appointment.appointmentId,
      day: appointment.startAt,
    ),
  );
}
