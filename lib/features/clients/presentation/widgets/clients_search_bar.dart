import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_icon_sizes.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';

class ClientsSearchBar extends StatelessWidget {
  const ClientsSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = AppStrings.clientsSearchHint,
    super.key,
  });

  static const _height = 48.0;

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  bool get _hasText => controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.borderMd,
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.graphite,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(Icons.search_rounded),
            prefixIconColor: AppColors.textSecondary,
            suffixIcon: _hasText
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                    iconSize: AppIconSizes.sm,
                    tooltip: AppStrings.cancel,
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          ),
        ),
      ),
    );
  }
}
