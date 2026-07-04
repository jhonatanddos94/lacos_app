import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_shortcut_card.dart';

class ClientShortcutsSection extends StatelessWidget {
  const ClientShortcutsSection({required this.shortcuts, super.key});

  static const _rowBreakpoint = 520.0;
  static const _scrollCardWidth = 156.0;

  final List<ClientShortcutPreview> shortcuts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _rowBreakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final shortcut in shortcuts) ...[
                  Expanded(
                    child: ClientShortcutCard(
                      shortcut: shortcut,
                      compact: true,
                    ),
                  ),
                  if (shortcut != shortcuts.last)
                    const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final shortcut in shortcuts) ...[
                SizedBox(
                  width: _scrollCardWidth,
                  child: ClientShortcutCard(
                    shortcut: shortcut,
                    compact: true,
                  ),
                ),
                if (shortcut != shortcuts.last)
                  const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        );
      },
    );
  }
}
