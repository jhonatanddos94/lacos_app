import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/domain/enums/appointment_canceled_by.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_quick_choice_chip.dart';

class AppointmentCancelDialog extends ConsumerStatefulWidget {
  const AppointmentCancelDialog({
    required this.appointmentId,
    required this.clientName,
    super.key,
  });

  final String appointmentId;
  final String clientName;

  @override
  ConsumerState<AppointmentCancelDialog> createState() =>
      _AppointmentCancelDialogState();
}

class _AppointmentCancelDialogState
    extends ConsumerState<AppointmentCancelDialog> {
  var _isConfirming = false;

  Future<void> _confirmCancel() async {
    if (_isConfirming) return;

    final controller = ref.read(cancelAppointmentControllerProvider.notifier);
    final currentState = ref.read(cancelAppointmentControllerProvider);
    if (currentState.isLoading || currentState.canceledBy == null) return;

    setState(() => _isConfirming = true);

    try {
      final canceledAppointment = await controller.cancel(widget.appointmentId);

      if (!mounted) return;

      if (canceledAppointment != null) {
        Navigator.of(context).pop(canceledAppointment);
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      } else {
        _isConfirming = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cancelAppointmentControllerProvider);
    final isLoading = state.isLoading || _isConfirming;
    final canConfirm = state.canceledBy != null && !isLoading;
    final errorMessage = state.errorMessage;

    return AlertDialog(
      title: const Text(AppStrings.appointmentCancelTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appointmentCancelClientLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              widget.clientName,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.appointmentCancelWhoCanceled,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            Wrap(
              spacing: AppSpacing.xxxs,
              runSpacing: AppSpacing.xxxs,
              children: [
                AppointmentQuickChoiceChip(
                  label: AppStrings.appointmentCancelByClient,
                  selected: state.canceledBy == AppointmentCanceledBy.client,
                  enabled: !isLoading,
                  onTap: () => ref
                      .read(cancelAppointmentControllerProvider.notifier)
                      .setCanceledBy(AppointmentCanceledBy.client),
                ),
                AppointmentQuickChoiceChip(
                  label: AppStrings.appointmentCancelBySalon,
                  selected: state.canceledBy == AppointmentCanceledBy.salon,
                  enabled: !isLoading,
                  onTap: () => ref
                      .read(cancelAppointmentControllerProvider.notifier)
                      .setCanceledBy(AppointmentCanceledBy.salon),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.appointmentCancelReasonLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            TextField(
              enabled: !isLoading,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: AppStrings.appointmentCancelReasonHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: ref
                  .read(cancelAppointmentControllerProvider.notifier)
                  .setCancellationReason,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.appointmentCancelMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                errorMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.appointmentCancelBack),
        ),
        FilledButton(
          onPressed: canConfirm ? _confirmCancel : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.softRose,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.softRose.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.7),
          ),
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text(AppStrings.appointmentCancelConfirm),
        ),
      ],
    );
  }
}
