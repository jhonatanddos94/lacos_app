import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_shortcut_card.dart';

class ClientShortcutsSection extends StatelessWidget {
  const ClientShortcutsSection({required this.shortcuts, super.key});

  final List<ClientShortcutPreview> shortcuts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final shortcut in shortcuts) ...[
            ClientShortcutCard(shortcut: shortcut),
            if (shortcut != shortcuts.last)
              const SizedBox(width: AppSpacing.xxs),
          ],
        ],
      ),
    );
  }
}
