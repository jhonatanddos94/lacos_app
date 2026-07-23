import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_quick_choice_chip.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_filters.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_sort_order.dart';
import 'package:lacos_app/features/memories/application/models/client_memory_visibility_filter.dart';
import 'package:lacos_app/features/memories/presentation/helpers/client_memory_labels.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ClientMemoryFiltersBottomSheet extends StatefulWidget {
  const ClientMemoryFiltersBottomSheet({
    required this.initialFilters,
    super.key,
  });

  final ClientMemoryFilters initialFilters;

  @override
  State<ClientMemoryFiltersBottomSheet> createState() =>
      _ClientMemoryFiltersBottomSheetState();
}

class _ClientMemoryFiltersBottomSheetState
    extends State<ClientMemoryFiltersBottomSheet> {
  late ClientMemoryFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilters;
  }

  void _updateDraft(ClientMemoryFilters filters) {
    setState(() => _draft = filters);
  }

  void _clearDraft() {
    setState(() => _draft = ClientMemoryFilters.defaults);
  }

  void _apply() {
    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderTopLg,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.memoryFiltersTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FilterSection(
                          label: AppStrings.memoryFilterShowLabel,
                          children: ClientMemoryVisibilityFilter.values.map((
                            visibility,
                          ) {
                            return AppointmentQuickChoiceChip(
                              label: ClientMemoryLabels.visibilityLabel(
                                visibility,
                              ),
                              selected: _draft.visibility == visibility,
                              onTap: () => _updateDraft(
                                _draft.copyWith(visibility: visibility),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _FilterSection(
                          label: AppStrings.memoryTypeLabel,
                          children: [
                            AppointmentQuickChoiceChip(
                              label: AppStrings.memoryFilterAll,
                              selected: _draft.type == null,
                              onTap: () => _updateDraft(
                                _draft.copyWith(clearType: true),
                              ),
                            ),
                            ...ClientMemoryType.values.map((type) {
                              return AppointmentQuickChoiceChip(
                                label: ClientMemoryLabels.typeLabel(type),
                                selected: _draft.type == type,
                                onTap: () =>
                                    _updateDraft(_draft.copyWith(type: type)),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _FilterSection(
                          label: AppStrings.memoryPriorityLabel,
                          children: [
                            AppointmentQuickChoiceChip(
                              label: AppStrings.memoryFilterAll,
                              selected: _draft.priority == null,
                              onTap: () => _updateDraft(
                                _draft.copyWith(clearPriority: true),
                              ),
                            ),
                            ...ClientMemoryPriority.values.map((priority) {
                              return AppointmentQuickChoiceChip(
                                label: ClientMemoryLabels.priorityLabel(
                                  priority,
                                ),
                                selected: _draft.priority == priority,
                                onTap: () => _updateDraft(
                                  _draft.copyWith(priority: priority),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _FilterSection(
                          label: AppStrings.memoryFilterSortLabel,
                          children: ClientMemorySortOrder.values.map((
                            sortOrder,
                          ) {
                            return AppointmentQuickChoiceChip(
                              label: ClientMemoryLabels.sortOrderLabel(
                                sortOrder,
                              ),
                              selected: _draft.sortOrder == sortOrder,
                              onTap: () => _updateDraft(
                                _draft.copyWith(sortOrder: sortOrder),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: AppStrings.memoryFilterClear,
                        variant: AppButtonVariant.outline,
                        onPressed: _clearDraft,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppButton(
                        label: AppStrings.memoryFilterApply,
                        onPressed: _apply,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxs),
        Wrap(
          spacing: AppSpacing.xxxs,
          runSpacing: AppSpacing.xxxs,
          children: children,
        ),
      ],
    );
  }
}
