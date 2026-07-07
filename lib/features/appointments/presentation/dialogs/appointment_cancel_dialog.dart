import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';

class AppointmentCancelDialog extends ConsumerStatefulWidget {
  const AppointmentCancelDialog({
    required this.appointmentId,
    super.key,
  });

  final String appointmentId;

  @override
  ConsumerState<AppointmentCancelDialog> createState() =>
      _AppointmentCancelDialogState();
}

class _AppointmentCancelDialogState extends ConsumerState<AppointmentCancelDialog> {
  Future<void> _confirmCancel() async {
    final canceledAppointment = await ref
        .read(cancelAppointmentControllerProvider.notifier)
        .cancel(widget.appointmentId);

    if (!mounted) return;

    if (canceledAppointment != null) {
      Navigator.of(context).pop(canceledAppointment);
      return;
    }

    final error = ref.read(cancelAppointmentControllerProvider).error;
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
      _ => AppStrings.appointmentCancelError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(cancelAppointmentControllerProvider).isLoading;

    return AlertDialog(
      title: const Text(AppStrings.appointmentCancelTitle),
      content: Text(
        AppStrings.appointmentCancelMessage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.appointmentCancelBack),
        ),
        FilledButton(
          onPressed: isLoading ? null : _confirmCancel,
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
