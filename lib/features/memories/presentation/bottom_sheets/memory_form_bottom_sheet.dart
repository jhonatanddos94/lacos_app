import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_field_sizes.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_quick_choice_chip.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_priority.dart';
import 'package:lacos_app/features/memories/domain/enums/client_memory_type.dart';
import 'package:lacos_app/features/memories/presentation/helpers/client_memory_labels.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class MemoryFormBottomSheet extends ConsumerStatefulWidget {
  const MemoryFormBottomSheet({required this.clientId, this.memory, super.key});

  final String clientId;
  final ClientMemory? memory;

  @override
  ConsumerState<MemoryFormBottomSheet> createState() =>
      _MemoryFormBottomSheetState();
}

class _MemoryFormBottomSheetState extends ConsumerState<MemoryFormBottomSheet> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  bool get _isEditing => widget.memory != null;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_handleContentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(memoryFormControllerProvider.notifier);
      if (widget.memory != null) {
        notifier.initializeForEdit(widget.memory!);
        _contentController.text = widget.memory!.content;
      } else {
        notifier.initializeForCreate();
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentController
      ..removeListener(_handleContentChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleContentChanged() {
    ref
        .read(memoryFormControllerProvider.notifier)
        .setContent(_contentController.text);
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _cancel() {
    if (ref.read(memoryFormControllerProvider).isSubmitting) return;
    Navigator.of(context).pop();
  }

  Future<void> _saveMemory() async {
    if (ref.read(memoryFormControllerProvider).isSubmitting) return;

    ref
        .read(memoryFormControllerProvider.notifier)
        .setContent(_contentController.text);

    final memory = await ref
        .read(memoryFormControllerProvider.notifier)
        .save(clientId: widget.clientId);

    if (!mounted) return;

    if (memory != null) {
      Navigator.of(context).pop(memory);
      return;
    }

    final errorMessage = ref.read(memoryFormControllerProvider).errorMessage;
    if (errorMessage != null) {
      _showMessage(errorMessage);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(memoryFormControllerProvider);
    final isSubmitting = formState.isSubmitting;
    final contentLength = _contentController.text.characters.length;

    return PopScope(
      canPop: !isSubmitting,
      child: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: Material(
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
                padding: EdgeInsets.only(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  top: AppSpacing.md,
                  bottom:
                      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MemoryFormHeader(isEditing: _isEditing),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: AppFieldSizes.memoryContentHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AppTextField(
                                controller: _contentController,
                                focusNode: _focusNode,
                                autofocus: true,
                                enabled: !isSubmitting,
                                label: AppStrings.memoryContentLabel,
                                hint: AppStrings.memoryContentHint,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                maxLength: AppFieldLimits.memoryContent,
                                errorText: formState.contentError,
                                expands: true,
                              ),
                            ),
                            if (formState.contentError == null)
                              Positioned(
                                right: AppSpacing.xxs,
                                bottom: AppSpacing.xxxs,
                                child: Text(
                                  '$contentLength / ${AppFieldLimits.memoryContent}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _MemoryChoiceSection(
                        label: AppStrings.memoryTypeLabel,
                        enabled: !isSubmitting,
                        children: ClientMemoryType.values.map((type) {
                          return AppointmentQuickChoiceChip(
                            label: ClientMemoryLabels.typeLabel(type),
                            selected: formState.type == type,
                            enabled: !isSubmitting,
                            onTap: () => ref
                                .read(memoryFormControllerProvider.notifier)
                                .setType(type),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MemoryChoiceSection(
                        label: AppStrings.memoryPriorityLabel,
                        enabled: !isSubmitting,
                        children: ClientMemoryPriority.values.map((priority) {
                          return AppointmentQuickChoiceChip(
                            label: ClientMemoryLabels.priorityLabel(priority),
                            selected: formState.priority == priority,
                            enabled: !isSubmitting,
                            onTap: () => ref
                                .read(memoryFormControllerProvider.notifier)
                                .setPriority(priority),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MemoryPinToggle(
                        value: formState.isPinned,
                        enabled: !isSubmitting,
                        onChanged: (value) => ref
                            .read(memoryFormControllerProvider.notifier)
                            .setPinned(value),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _MemoryTipCard(),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: _isEditing
                            ? AppStrings.saveChanges
                            : AppStrings.saveMemory,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : _saveMemory,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton(
                        label: AppStrings.cancel,
                        variant: AppButtonVariant.text,
                        onPressed: isSubmitting ? null : _cancel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryPinToggle extends StatelessWidget {
  const _MemoryPinToggle({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.memoryPinLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                AppStrings.memoryPinHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: AppColors.lacosPurple,
        ),
      ],
    );
  }
}

class _MemoryChoiceSection extends StatelessWidget {
  const _MemoryChoiceSection({
    required this.label,
    required this.children,
    this.enabled = true,
  });

  final String label;
  final List<Widget> children;
  final bool enabled;

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

class _MemoryFormHeader extends StatelessWidget {
  const _MemoryFormHeader({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.lg,
          height: AppSpacing.lg,
          decoration: BoxDecoration(
            color: AppColors.purple50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isEditing ? Icons.edit_outlined : Icons.auto_awesome_rounded,
            color: AppColors.purple700,
            size: AppSpacing.sm,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? AppStrings.editMemory
                    : AppStrings.memoryRegisterTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                isEditing
                    ? AppStrings.editMemorySubtitle
                    : AppStrings.newMemorySubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemoryTipCard extends StatelessWidget {
  const _MemoryTipCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.purple50.withValues(alpha: 0.55),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.purple100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.purple700,
            size: AppSpacing.sm,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '${AppStrings.memoryTipTitle} ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.purple800,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const TextSpan(text: AppStrings.memoryTipBody),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
