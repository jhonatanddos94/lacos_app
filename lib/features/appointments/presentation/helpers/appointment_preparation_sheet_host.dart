import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/mappers/appointment_preparation_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/models/appointment_preparation_action.dart';

Future<AppointmentPreparationAction> showAppointmentPreparationBottomSheet({
  required BuildContext context,
  required AgendaAppointmentDisplay appointment,
}) async {
  if (!context.mounted) {
    return AppointmentPreparationAction.dismiss;
  }

  final data = AppointmentPreparationMapper.fromDisplay(appointment);

  final action = await showModalBottomSheet<AppointmentPreparationAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) => AppointmentPreparationBottomSheet(data: data),
  );

  return action ?? AppointmentPreparationAction.dismiss;
}
