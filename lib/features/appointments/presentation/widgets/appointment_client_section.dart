import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/client_form_formatters.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_select_tile.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';

class AppointmentClientSection extends StatelessWidget {
  const AppointmentClientSection({
    required this.selectedClient,
    required this.errorText,
    required this.onTap,
    super.key,
  });

  final Client? selectedClient;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppointmentFormSection(
      icon: Icons.person_outline_rounded,
      title: AppStrings.appointmentClientSection,
      subtitle: AppStrings.appointmentClientSectionSubtitle,
      errorText: errorText,
      child: AppointmentFormSelectTile(
        title: selectedClient?.name ?? AppStrings.appointmentChooseClientPrompt,
        subtitle: selectedClient == null
            ? AppStrings.appointmentChooseClientHint
            : formatBrazilianPhone(selectedClient!.phone),
        leading: selectedClient == null
            ? const AppointmentFormIconCircle(icon: Icons.search_rounded)
            : ClientAvatar(
                name: selectedClient!.name,
                photoUrl: selectedClient!.photoUrl,
                radius: 22,
              ),
        hasError: errorText != null,
        onTap: onTap,
      ),
    );
  }
}
