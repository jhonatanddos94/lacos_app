import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/application/models/complete_appointment_flow_result.dart';
import 'package:lacos_app/features/appointments/presentation/models/complete_appointment_success_action.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/presentation/helpers/memory_form_sheet_host.dart';

Future<void> handleCompleteAppointmentMemoryFlow({
  required BuildContext context,
  required WidgetRef ref,
  required CompleteAppointmentFlowResult result,
}) async {
  if (result.successAction != CompleteAppointmentSuccessAction.addMemory) {
    return;
  }

  final memory = await showMemoryFormBottomSheet(
    context: context,
    clientId: result.appointment.clientId,
  );

  if (!context.mounted) return;

  if (memory != null) {
    ref.invalidate(clientMemoriesProvider(result.appointment.clientId));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.memoryRegisteredSuccess)),
    );
  }
}
