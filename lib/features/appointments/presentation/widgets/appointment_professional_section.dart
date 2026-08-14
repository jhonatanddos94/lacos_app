import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_select_tile.dart';
import 'package:lacos_app/features/clients/presentation/widgets/client_avatar.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';

enum AppointmentProfessionalUiMode {
  loading,
  error,
  incomplete,
  readOnly,
  selectable,
}

class AppointmentProfessionalSection extends StatelessWidget {
  const AppointmentProfessionalSection({
    required this.mode,
    required this.selectedProfessional,
    required this.errorText,
    this.onTap,
    this.onRetry,
    this.onCompleteProfileTap,
    super.key,
  });

  static const readOnlyKey = Key('appointment-professional-readonly');
  static const selectableKey = Key('appointment-professional-selectable');
  static const loadingKey = Key('appointment-professional-loading');
  static const errorKey = Key('appointment-professional-error');
  static const incompleteKey = Key('appointment-professional-incomplete');

  final AppointmentProfessionalUiMode mode;
  final Professional? selectedProfessional;
  final String? errorText;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onCompleteProfileTap;

  @override
  Widget build(BuildContext context) {
    final professional = selectedProfessional;
    final subtitle = switch (mode) {
      AppointmentProfessionalUiMode.incomplete =>
        AppStrings.appointmentProfessionalIncompleteHint,
      AppointmentProfessionalUiMode.error =>
        AppStrings.appointmentProfessionalLoadError,
      AppointmentProfessionalUiMode.readOnly => professional == null
          ? null
          : _formatProfessionalSubtitle(professional),
      AppointmentProfessionalUiMode.selectable => professional == null
          ? AppStrings.appointmentChooseProfessionalHint
          : _formatProfessionalSubtitle(professional),
      AppointmentProfessionalUiMode.loading => null,
    };

    return AppointmentFormSection(
      icon: Icons.badge_outlined,
      title: AppStrings.appointmentProfessionalSection,
      subtitle: AppStrings.appointmentProfessionalSectionSubtitle,
      errorText: errorText,
      actionLabel: switch (mode) {
        AppointmentProfessionalUiMode.incomplete
            when onCompleteProfileTap != null =>
          AppStrings.appointmentProfessionalCompleteProfileCta,
        AppointmentProfessionalUiMode.error when onRetry != null =>
          AppStrings.tryAgain,
        _ => null,
      },
      onActionTap: switch (mode) {
        AppointmentProfessionalUiMode.incomplete => onCompleteProfileTap,
        AppointmentProfessionalUiMode.error => onRetry,
        _ => null,
      },
      child: switch (mode) {
        AppointmentProfessionalUiMode.loading => const _ProfessionalLoading(),
        AppointmentProfessionalUiMode.error => _ProfessionalStatusTile(
          key: errorKey,
          title: AppStrings.appointmentProfessionalLoadError,
        ),
        AppointmentProfessionalUiMode.incomplete => _ProfessionalStatusTile(
          key: incompleteKey,
          title: AppStrings.appointmentProfessionalNotConfigured,
          subtitle: subtitle,
        ),
        AppointmentProfessionalUiMode.readOnly => AppointmentFormSelectTile(
          key: readOnlyKey,
          title: professional?.name ?? AppStrings.appointmentProfessionalSection,
          subtitle: subtitle,
          leading: professional == null
              ? const AppointmentFormIconCircle(icon: Icons.badge_outlined)
              : ClientAvatar(name: professional.name, radius: 22),
        ),
        AppointmentProfessionalUiMode.selectable => AppointmentFormSelectTile(
          key: selectableKey,
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
      },
    );
  }
}

class _ProfessionalLoading extends StatelessWidget {
  const _ProfessionalLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: AppointmentProfessionalSection.loadingKey,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ProfessionalStatusTile extends StatelessWidget {
  const _ProfessionalStatusTile({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppointmentFormSelectTile(title: title, subtitle: subtitle);
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
