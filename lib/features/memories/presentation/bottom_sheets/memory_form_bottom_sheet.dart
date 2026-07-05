import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_field_sizes.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/config/app_validation_messages.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class MemoryFormBottomSheet extends ConsumerStatefulWidget {
  const MemoryFormBottomSheet({
    required this.clientId,
    this.memory,
    super.key,
  });

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
    _initializeFields();
    _contentController.addListener(_handleContentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoryFormControllerProvider.notifier).reset();
      _focusNode.requestFocus();
    });
  }

  void _initializeFields() {
    final memory = widget.memory;
    if (memory == null) return;

    _contentController.text = memory.content;
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
    setState(() {});
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _cancel() {
    if (ref.read(memoryFormControllerProvider).isLoading) return;
    Navigator.of(context).pop();
  }

  Future<void> _saveMemory() async {
    if (ref.read(memoryFormControllerProvider).isLoading) return;

    final memory = await ref.read(memoryFormControllerProvider.notifier).save(
          clientId: widget.clientId,
          content: _contentController.text,
          initialMemory: widget.memory,
        );

    if (!mounted) return;

    if (memory != null) {
      Navigator.of(context).pop(memory);
      return;
    }

    final error = ref.read(memoryFormControllerProvider).error;
    if (error != null) {
      _showMessage(_resolveErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _resolveErrorMessage(Object error) {
    return switch (error) {
      FormatException(message: final message) => message,
      StateError(message: final message) => message,
      _ =>
        '${AppValidationMessages.unexpectedError} '
            '${AppValidationMessages.tryAgain}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(memoryFormControllerProvider);
    final isLoading = state.isLoading;
    final contentLength = _contentController.text.characters.length;

    return PopScope(
      canPop: !isLoading,
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
                                enabled: !isLoading,
                                label: AppStrings.memoryContentLabel,
                                hint: AppStrings.memoryContentHint,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                maxLength: AppFieldLimits.memoryContent,
                                expands: true,
                              ),
                            ),
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
                      const SizedBox(height: AppSpacing.sm),
                      const _MemoryTipCard(),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: _isEditing
                            ? AppStrings.saveChanges
                            : AppStrings.saveMemory,
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _saveMemory,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton(
                        label: AppStrings.cancel,
                        variant: AppButtonVariant.text,
                        onPressed: isLoading ? null : _cancel,
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
                isEditing ? AppStrings.editMemory : AppStrings.newMemory,
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
