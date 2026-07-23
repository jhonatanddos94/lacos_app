import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_filters.dart';
import 'package:lacos_app/features/memories/presentation/bottom_sheets/client_memory_filters_bottom_sheet.dart';

Future<ClientMemoryFilters?> showClientMemoryFiltersBottomSheet({
  required BuildContext context,
  required ClientMemoryFilters initialFilters,
}) {
  return showModalBottomSheet<ClientMemoryFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
    builder: (context) =>
        ClientMemoryFiltersBottomSheet(initialFilters: initialFilters),
  );
}
