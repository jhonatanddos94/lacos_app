import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/complete_appointment_success_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/models/complete_appointment_success_action.dart';

Future<CompleteAppointmentSuccessAction>
showCompleteAppointmentSuccessBottomSheet({
  required BuildContext context,
}) async {
  final action = await showModalBottomSheet<CompleteAppointmentSuccessAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) => const CompleteAppointmentSuccessBottomSheet(),
  );

  return action ?? CompleteAppointmentSuccessAction.dismiss;
}
