import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_select_tile.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_selected_service_tile.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';

class AppointmentServicesSection extends StatelessWidget {
  const AppointmentServicesSection({
    required this.selectedServices,
    required this.errorText,
    required this.onAddService,
    required this.onServiceTap,
    super.key,
  });

  final List<Service> selectedServices;
  final String? errorText;
  final VoidCallback onAddService;
  final void Function(Service service, int index) onServiceTap;

  @override
  Widget build(BuildContext context) {
    return AppointmentFormSection(
      icon: Icons.content_cut_rounded,
      title: AppStrings.appointmentServiceSection,
      subtitle: AppStrings.appointmentServiceSectionSubtitle,
      errorText: errorText,
      child: _ServicesContent(
        selectedServices: selectedServices,
        hasError: errorText != null,
        onAddService: onAddService,
        onServiceTap: onServiceTap,
      ),
    );
  }
}

class _ServicesContent extends StatelessWidget {
  const _ServicesContent({
    required this.selectedServices,
    required this.hasError,
    required this.onAddService,
    required this.onServiceTap,
  });

  final List<Service> selectedServices;
  final bool hasError;
  final VoidCallback onAddService;
  final void Function(Service service, int index) onServiceTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasServices = selectedServices.isNotEmpty;

    return AnimatedSize(
      duration: AppDurations.normal,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppDurations.normal,
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: hasServices
            ? Column(
                key: const ValueKey('services-list'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (
                    var index = 0;
                    index < selectedServices.length;
                    index++
                  ) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.xs),
                    AppointmentSelectedServiceTile(
                      service: selectedServices[index],
                      onTap: () => onServiceTap(selectedServices[index], index),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onAddService,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.lacosPurple,
                      ),
                      child: Text(
                        AppStrings.appointmentAddAnotherService,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.lacosPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : AppointmentFormSelectTile(
                key: const ValueKey('services-empty'),
                title: AppStrings.appointmentAddServicePrompt,
                subtitle: AppStrings.appointmentAddServiceHint,
                leading: const AppointmentFormIconCircle(
                  icon: Icons.add_rounded,
                ),
                hasError: hasError,
                onTap: onAddService,
              ),
      ),
    );
  }
}
