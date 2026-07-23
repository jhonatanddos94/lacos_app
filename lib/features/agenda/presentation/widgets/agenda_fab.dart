import 'package:flutter/material.dart';

import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';

class AgendaFab extends StatelessWidget {
  const AgendaFab({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.level2,
      ),
      child: FloatingActionButton.extended(
        heroTag: 'agenda_fab',
        onPressed: onPressed,
        backgroundColor: AppColors.lacosPurple,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo'),
      ),
    );
  }
}
