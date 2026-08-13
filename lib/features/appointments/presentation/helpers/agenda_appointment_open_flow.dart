import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/domain/services/appointment_preparation_eligibility.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_details_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_preparation_sheet_host.dart';
import 'package:lacos_app/features/appointments/presentation/models/appointment_preparation_action.dart';

/// Impede abertura duplicada por toques rápidos enquanto o fluxo está ativo.
var _isOpeningAgendaAppointment = false;

@visibleForTesting
bool get isOpeningAgendaAppointmentForTest => _isOpeningAgendaAppointment;

@visibleForTesting
void resetAgendaAppointmentOpenGuardForTest() {
  _isOpeningAgendaAppointment = false;
}

Future<Object?> openAgendaAppointmentFlow({
  required BuildContext context,
  required AgendaAppointmentDisplay appointment,
  DateTime? now,
}) async {
  if (_isOpeningAgendaAppointment) {
    return null;
  }

  _isOpeningAgendaAppointment = true;

  try {
    final referenceNow = now ?? DateTime.now();
    final isEligible = AppointmentPreparationEligibility.isEligible(
      status: appointment.status,
      startAt: appointment.startAt,
      endAt: appointment.endAt,
      now: referenceNow,
    );

    if (isEligible) {
      final preparationAction = await showAppointmentPreparationBottomSheet(
        context: context,
        appointment: appointment,
      );

      if (!context.mounted) {
        return null;
      }

      if (preparationAction == AppointmentPreparationAction.dismiss) {
        return null;
      }
    }

    return await showModalBottomSheet<Object?>(
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
  } finally {
    _isOpeningAgendaAppointment = false;
  }
}
