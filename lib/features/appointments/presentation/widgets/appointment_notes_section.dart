import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_field_limits.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_section.dart';
import 'package:lacos_app/shared/widgets/inputs/app_text_field.dart';

class AppointmentNotesSection extends StatelessWidget {
  const AppointmentNotesSection({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppointmentFormSection(
      icon: Icons.chat_bubble_outline_rounded,
      title: AppStrings.appointmentNotesSection,
      subtitle: AppStrings.appointmentNotesSectionSubtitle,
      child: Stack(
        children: [
          AppTextField(
            controller: controller,
            hint: AppStrings.appointmentNotesHint,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            minLines: 4,
            maxLength: AppFieldLimits.appointmentNotes,
          ),
          Positioned(
            right: AppSpacing.xxs,
            bottom: AppSpacing.xxxs,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return Text(
                  '${value.text.characters.length}/'
                  '${AppFieldLimits.appointmentNotes}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
