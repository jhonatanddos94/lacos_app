import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/agenda/application/models/agenda_appointment_display.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_preparation_data.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_preparation_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/mappers/appointment_preparation_mapper.dart';
import 'package:lacos_app/features/appointments/presentation/models/appointment_preparation_action.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';

Future<AppointmentPreparationAction> showAppointmentPreparationBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AgendaAppointmentDisplay appointment,
}) async {
  final preparationData = await _loadPreparationData(
    ref: ref,
    appointment: appointment,
  );

  await _touchDisplayedMemories(
    ref: ref,
    preparationData: preparationData,
  );

  if (!context.mounted) {
    return AppointmentPreparationAction.dismiss;
  }

  final action = await showModalBottomSheet<AppointmentPreparationAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) => AppointmentPreparationBottomSheet(
      data: preparationData,
    ),
  );

  return action ?? AppointmentPreparationAction.dismiss;
}

Future<AppointmentPreparationData> _loadPreparationData({
  required WidgetRef ref,
  required AgendaAppointmentDisplay appointment,
}) async {
  try {
    final memories = await ref.read(
      clientMemoriesProvider(appointment.clientId).future,
    );

    return AppointmentPreparationMapper.from(
      appointment: appointment,
      memories: memories,
    );
  } on Object {
    return AppointmentPreparationMapper.from(
      appointment: appointment,
      memories: const [],
    );
  }
}

Future<void> _touchDisplayedMemories({
  required WidgetRef ref,
  required AppointmentPreparationData preparationData,
}) async {
  final memoryIds = preparationData.memories
      .map((memory) => memory.memoryId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  if (memoryIds.isEmpty) {
    return;
  }

  try {
    await ref
        .read(clientMemoryRepositoryProvider)
        .touchMentioned(memoryIds: memoryIds);
    ref.invalidate(clientMemoriesProvider(preparationData.clientId));
  } on Object {
    return;
  }
}
