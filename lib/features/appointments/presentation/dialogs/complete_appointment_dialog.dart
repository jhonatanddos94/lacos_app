import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/service_records/domain/entities/service_record.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class CompleteAppointmentDialog extends ConsumerStatefulWidget {
  const CompleteAppointmentDialog({
    required this.appointmentId,
    required this.clientName,
    required this.services,
    super.key,
  });

  final String appointmentId;
  final String clientName;
  final List<Service> services;

  @override
  ConsumerState<CompleteAppointmentDialog> createState() =>
      _CompleteAppointmentDialogState();
}

class _CompleteAppointmentDialogState
    extends ConsumerState<CompleteAppointmentDialog> {
  var _isConfirming = false;

  Future<void> _confirmComplete() async {
    if (_isConfirming) return;

    final controller = ref.read(completeAppointmentControllerProvider.notifier);
    if (ref.read(completeAppointmentControllerProvider).isLoading) return;

    setState(() => _isConfirming = true);
    debugPrint('[AppointmentComplete] dialog confirm tapped');

    try {
      final mentionedMemoryIds = ref
          .read(appointmentMemoryUsageProvider(widget.appointmentId))
          .usedMemoryIds
          .toList(growable: false);

      final serviceRecord = await controller.complete(
        widget.appointmentId,
        mentionedMemoryIds: mentionedMemoryIds,
      );

      if (!mounted) return;

      if (serviceRecord != null) {
        Navigator.of(context).pop<ServiceRecord>(serviceRecord);
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
    final state = ref.watch(completeAppointmentControllerProvider);
    final isLoading = state.isLoading || _isConfirming;
    final errorMessage = state.errorMessage;

    return AlertDialog(
      title: const Text(AppStrings.appointmentCompleteTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appointmentCompleteClientLabel,
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
              AppStrings.appointmentCompleteServicesLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxs),
            for (final service in widget.services) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.purple500,
                  ),
                  const SizedBox(width: AppSpacing.xxxs),
                  Expanded(
                    child: Text(
                      service.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.graphite,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxs),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.appointmentCompleteMessage,
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
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: isLoading ? null : _confirmComplete,
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text(AppStrings.appointmentCompleteConfirm),
        ),
      ],
    );
  }
}
