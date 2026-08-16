import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/features/clients/domain/entities/client_preview_data.dart';
import 'package:lacos_app/features/clients/domain/enums/client_list_filter.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_shortcut_card.dart';

class ClientShortcutsSection extends StatelessWidget {
  const ClientShortcutsSection({
    required this.shortcuts,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static const barKey = Key('client-filters-bar');

  final List<ClientShortcutPreview> shortcuts;
  final ClientListFilter selected;
  final ValueChanged<ClientListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMinInteractiveDimension,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: ClientShortcutCard.visualHeight,
            width: double.infinity,
            child: DecoratedBox(
              key: barKey,
              decoration: BoxDecoration(
                color: AppColors.purple50,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: AppColors.divider),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ClientShortcutCard.hitVisualInset,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.borderMd,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final shortcut in shortcuts)
                      Expanded(
                        child: ClientShortcutCard(
                          shortcut: ClientShortcutPreview(
                            label: shortcut.label,
                            type: shortcut.type,
                            isSelected: shortcut.type == selected,
                            isEnabled: shortcut.isEnabled,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final shortcut in shortcuts)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: shortcut.type == selected,
                    enabled: shortcut.isEnabled,
                    label: shortcut.label,
                    excludeSemantics: true,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        key: ClientShortcutCard.chipKey(shortcut.type),
                        onTap: shortcut.isEnabled
                            ? () => onSelected(shortcut.type)
                            : null,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
