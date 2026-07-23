import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_select_tile.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';

class AppointmentProfessionalSection extends StatelessWidget {
  const AppointmentProfessionalSection({
    required this.selectedProfessional,
    required this.errorText,
    required this.onTap,
    super.key,
  });

  final Professional? selectedProfessional;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final professional = selectedProfessional;
    final subtitle = professional == null
        ? AppStrings.appointmentChooseProfessionalHint
        : _formatProfessionalSubtitle(professional);

    return AppointmentFormSection(
      icon: Icons.badge_outlined,
      title: AppStrings.appointmentProfessionalSection,
      subtitle: AppStrings.appointmentProfessionalSectionSubtitle,
      errorText: errorText,
      child: AppointmentFormSelectTile(
        title:
            professional?.name ??
            AppStrings.appointmentChooseProfessionalPrompt,
        subtitle: subtitle,
        leading: professional == null
            ? const AppointmentFormIconCircle(icon: Icons.search_rounded)
            : ClientAvatar(name: professional.name, radius: 22),
        hasError: errorText != null,
        onTap: onTap,
      ),
    );
  }
}

String? _formatProfessionalSubtitle(Professional professional) {
  final specialties = professional.specialties?.trim();
  if (specialties != null && specialties.isNotEmpty) {
    return specialties;
  }

  final role = professional.role?.trim();
  if (role != null && role.isNotEmpty) {
    return role;
  }

  return null;
}
