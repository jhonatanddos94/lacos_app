import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class AgendaFab extends StatelessWidget {
  const AgendaFab({
    required this.onPressed,
    this.inset = AppSpacing.md,
    super.key,
  });

  final VoidCallback onPressed;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: inset,
      bottom: inset,
      child: FloatingActionButton.extended(
        heroTag: 'agenda_fab',
        onPressed: onPressed,
        backgroundColor: AppColors.lacosPurple,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo'),
      ),
    );
  }
}
