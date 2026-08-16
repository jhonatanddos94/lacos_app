import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';
import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';

final clientShortcutsProvider = Provider<List<ClientShortcutPreview>>((ref) {
  return const [
    ClientShortcutPreview(
      label: AppStrings.allClients,
      type: ClientListFilter.all,
    ),
    ClientShortcutPreview(
      label: AppStrings.favoriteClients,
      type: ClientListFilter.favorites,
    ),
  ];
});
