import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/memory_form_bottom_sheet.dart';

Future<ClientMemory?> showMemoryFormBottomSheet({
  required BuildContext context,
  required String clientId,
  ClientMemory? memory,
}) {
  return showModalBottomSheet<ClientMemory>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) => MemoryFormBottomSheet(
      clientId: clientId,
      memory: memory,
    ),
  );
}
