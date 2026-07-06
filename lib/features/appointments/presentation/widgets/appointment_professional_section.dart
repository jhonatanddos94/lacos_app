import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_select_tile.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';

class AppointmentProfessionalSection extends StatelessWidget {
  const AppointmentProfessionalSection({
    required this.professionalName,
    required this.professionalSpecialty,
    required this.errorText,
    required this.onTap,
    super.key,
  });

  final String? professionalName;
  final String? professionalSpecialty;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppointmentFormSection(
      icon: Icons.badge_outlined,
      title: AppStrings.appointmentProfessionalSection,
      subtitle: AppStrings.appointmentProfessionalSectionSubtitle,
      errorText: errorText,
      child: AppointmentFormSelectTile(
        title: professionalName ??
            AppStrings.appointmentChooseProfessionalPrompt,
        subtitle: professionalName == null
            ? AppStrings.appointmentChooseProfessionalHint
            : professionalSpecialty,
        leading: professionalName == null
            ? const AppointmentFormIconCircle(icon: Icons.search_rounded)
            : ClientAvatar(
                name: professionalName!,
                radius: 22,
              ),
        hasError: errorText != null,
        onTap: onTap,
      ),
    );
  }
}
