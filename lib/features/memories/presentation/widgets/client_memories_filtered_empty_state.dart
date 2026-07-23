import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/home/presentation/widgets/home_empty_state.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class ClientMemoriesFilteredEmptyState extends StatelessWidget {
  const ClientMemoriesFilteredEmptyState({
    required this.onClearFilters,
    super.key,
  });

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HomeEmptyState(
            icon: Icons.filter_list_off_rounded,
            title: AppStrings.memoryFilterEmptyTitle,
            message: AppStrings.memoryFilterEmptyMessage,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: AppStrings.memoryFilterClearAction,
            variant: AppButtonVariant.text,
            onPressed: onClearFilters,
          ),
        ],
      ),
    );
  }
}
