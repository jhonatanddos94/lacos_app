import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';

final clientShortcutsProvider = Provider<List<ClientShortcutPreview>>((ref) {
  return const [
    ClientShortcutPreview(
      label: AppStrings.allClients,
      type: ClientShortcutType.all,
      isSelected: true,
    ),
    ClientShortcutPreview(
      label: AppStrings.favoriteClients,
      type: ClientShortcutType.favorites,
    ),
    ClientShortcutPreview(
      label: AppStrings.recentClients,
      type: ClientShortcutType.recent,
    ),
    ClientShortcutPreview(
      label: AppStrings.clientsWithoutReturn,
      type: ClientShortcutType.withoutReturn,
    ),
  ];
});
