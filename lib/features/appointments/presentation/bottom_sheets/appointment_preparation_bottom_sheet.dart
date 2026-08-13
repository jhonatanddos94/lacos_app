import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/core/widgets/app_skeleton_box.dart';
import 'package:lacos_app/features/appointments/application/helpers/appointment_preparation_memory_sorter.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_preparation_data.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_preparation_memory_item.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_preparation_memory_touch.dart';
import 'package:lacos_app/features/appointments/presentation/models/appointment_preparation_action.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_header.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/memories/application/memory_providers.dart';
import 'package:lacos_app/features/memories/domain/entities/client_memory.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class AppointmentPreparationBottomSheet extends ConsumerStatefulWidget {
  const AppointmentPreparationBottomSheet({required this.data, super.key});

  static const memoriesLoadingKey = Key(
    'appointment-preparation-memories-loading',
  );
  static const memoriesErrorKey = Key('appointment-preparation-memories-error');

  final AppointmentPreparationData data;

  @override
  ConsumerState<AppointmentPreparationBottomSheet> createState() =>
      _AppointmentPreparationBottomSheetState();
}

class _AppointmentPreparationBottomSheetState
    extends ConsumerState<AppointmentPreparationBottomSheet> {
  var _didPop = false;
  String? _touchSignature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientId = widget.data.clientId;
    final memoriesAsync = ref.watch(clientMemoriesProvider(clientId));

    ref.listen<AsyncValue<List<ClientMemory>>>(
      clientMemoriesProvider(clientId),
      (previous, next) {
        next.whenData(_scheduleTouchIfDisplayed);
      },
    );
    memoriesAsync.whenData(_scheduleTouchIfDisplayed);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.88,
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.borderTopLg,
          boxShadow: AppShadows.level2,
        ),
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.xs,
          bottom: AppSpacing.lg,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppointmentBottomSheetHandle(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: AppIconSizes.lg,
                        color: AppColors.purple700,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppStrings.appointmentPreparationTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        AppStrings.appointmentPreparationSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ClientSection(data: widget.data),
                      const SizedBox(height: AppSpacing.md),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider.withValues(alpha: 0.65),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _MemoriesSection(
                        memoriesAsync: memoriesAsync,
                        onRetry: () =>
                            ref.invalidate(clientMemoriesProvider(clientId)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: AppStrings.appointmentPreparationContinue,
                onPressed: () =>
                    _pop(AppointmentPreparationAction.continueToAppointment),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: AppStrings.appointmentPreparationNotNow,
                variant: AppButtonVariant.text,
                onPressed: () => _pop(AppointmentPreparationAction.dismiss),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pop(AppointmentPreparationAction action) {
    if (_didPop || !mounted) {
      return;
    }

    _didPop = true;
    Navigator.of(context).pop(action);
  }

  void _scheduleTouchIfDisplayed(List<ClientMemory> memories) {
    final items = AppointmentPreparationMemorySorter.selectTop(
      memories: memories,
    );
    final ids = items
        .map((item) => item.memoryId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    if (ids.isEmpty) {
      return;
    }

    final signature = ids.join('|');
    if (_touchSignature == signature) {
      return;
    }

    _touchSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(
        touchDisplayedPreparationMemories(
          repository: ref.read(clientMemoryRepositoryProvider),
          memoryIds: ids,
        ),
      );
    });
  }
}

class _ClientSection extends StatelessWidget {
  const _ClientSection({required this.data});

  final AppointmentPreparationData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.appointmentPreparationClientSection,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.purple800,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClientAvatar(
              name: data.clientName,
              photoUrl: data.clientPhotoUrl,
              radius: 28,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.clientName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _InfoLine(
                    label: AppStrings.appointmentPreparationServicesLabel,
                    value: data.servicesSummary,
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  _InfoLine(
                    label: AppStrings.appointmentPreparationScheduleLabel,
                    value: data.scheduleTimeLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.graphite,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _MemoriesSection extends StatelessWidget {
  const _MemoriesSection({required this.memoriesAsync, required this.onRetry});

  final AsyncValue<List<ClientMemory>> memoriesAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.appointmentPreparationMemoriesSection,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.purple800,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        memoriesAsync.when(
          loading: () => const _MemoriesLoading(),
          error: (_, _) => _MemoriesError(onRetry: onRetry),
          data: (memories) {
            final items = AppointmentPreparationMemorySorter.selectTop(
              memories: memories,
            );
            if (items.isEmpty) {
              return Text(
                AppStrings.appointmentPreparationMemoriesEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final memory in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _MemoryCard(memory: memory),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MemoriesLoading extends StatelessWidget {
  const _MemoriesLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.clientMemoryImportantLoadingLabel,
      child: Column(
        key: AppointmentPreparationBottomSheet.memoriesLoadingKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          AppSkeletonBox(width: double.infinity, height: 48),
          SizedBox(height: AppSpacing.xs),
          AppSkeletonBox(width: double.infinity, height: 48),
        ],
      ),
    );
  }
}

class _MemoriesError extends StatelessWidget {
  const _MemoriesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: AppointmentPreparationBottomSheet.memoriesErrorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.clientMemoriesLoadError,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(AppStrings.tryAgain)),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory});

  final AppointmentPreparationMemoryItem memory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.purple100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(memory.displayEmoji, style: theme.textTheme.titleSmall),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              memory.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.graphite,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
