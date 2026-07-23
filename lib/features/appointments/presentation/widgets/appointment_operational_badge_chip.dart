import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_operational_badge_mapper.dart';

class AppointmentOperationalBadgeChip extends StatelessWidget {
  const AppointmentOperationalBadgeChip({
    required this.presentation,
    super.key,
  });

  final AppointmentOperationalBadgePresentation presentation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: presentation.backgroundColor,
          borderRadius: AppRadius.borderSm,
        ),
        child: Text(
          presentation.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: presentation.foregroundColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            height: 1.15,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
