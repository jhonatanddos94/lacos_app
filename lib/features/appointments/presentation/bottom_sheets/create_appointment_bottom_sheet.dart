import 'package:flutter/material.dart';

import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_selected_service_actions_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_client_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_date_time_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_header.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_notes_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_professional_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_services_section.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/bottom_sheets/client_picker_bottom_sheet.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/presentation/bottom_sheets/service_picker_bottom_sheet.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class CreateAppointmentBottomSheet extends StatefulWidget {
  const CreateAppointmentBottomSheet({super.key});

  @override
  State<CreateAppointmentBottomSheet> createState() =>
      _CreateAppointmentBottomSheetState();
}

class _CreateAppointmentBottomSheetState
    extends State<CreateAppointmentBottomSheet> {
  static const _emptyTimeLabel = '--:--';

  final _scrollController = ScrollController();
  final _clientSectionKey = GlobalKey();
  final _servicesSectionKey = GlobalKey();
  final _professionalSectionKey = GlobalKey();
  final _dateTimeSectionKey = GlobalKey();

  final _notesController = TextEditingController();
  Client? _selectedClient;
  List<Service> _selectedServices = [];
  String? _selectedProfessionalName;
  String? _selectedProfessionalSpecialty;
  String? _selectedDateLabel;
  int? _selectedStartTimeMinutes;

  String? _clientError;
  String? _servicesError;
  String? _professionalError;
  String? _dateError;
  String? _startTimeError;

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _confirmAppointment() {
    if (!_validateForm()) return;
    _showMessage(AppStrings.appointmentSaveComingSoon);
  }

  bool _validateForm() {
    final clientError = _selectedClient == null
        ? AppStrings.appointmentClientRequired
        : null;
    final servicesError = _selectedServices.isEmpty
        ? AppStrings.appointmentAddAtLeastOneService
        : null;
    final professionalError = _selectedProfessionalName == null
        ? AppStrings.appointmentProfessionalRequired
        : null;
    final dateError = _selectedDateLabel == null
        ? AppStrings.appointmentDateRequired
        : null;
    final startTimeError = _selectedStartTimeMinutes == null
        ? AppStrings.appointmentStartTimeRequired
        : null;

    setState(() {
      _clientError = clientError;
      _servicesError = servicesError;
      _professionalError = professionalError;
      _dateError = dateError;
      _startTimeError = startTimeError;
    });

    if (clientError != null) {
      _scrollToSection(_clientSectionKey);
      return false;
    }
    if (servicesError != null) {
      _scrollToSection(_servicesSectionKey);
      return false;
    }
    if (professionalError != null) {
      _scrollToSection(_professionalSectionKey);
      return false;
    }
    if (dateError != null || startTimeError != null) {
      _scrollToSection(_dateTimeSectionKey);
      return false;
    }

    return true;
  }

  void _scrollToSection(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sectionContext = key.currentContext;
      if (sectionContext == null) return;

      Scrollable.ensureVisible(
        sectionContext,
        duration: AppDurations.normal,
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    });
  }

  int get _totalDurationMinutes {
    return _selectedServices.fold<int>(
      0,
      (total, service) => total + (service.durationMinutes ?? 0),
    );
  }

  double? get _totalPrice {
    double? total;

    for (final service in _selectedServices) {
      final price = service.price;
      if (price == null) continue;
      total = (total ?? 0) + price;
    }

    return total;
  }

  bool get _hasSelectedServicePrices {
    return _selectedServices.any((service) => service.price != null);
  }

  String get _startTimeDisplay {
    final startMinutes = _selectedStartTimeMinutes;
    if (startMinutes == null) {
      return _emptyTimeLabel;
    }

    return _formatTimeFromMinutes(startMinutes);
  }

  String get _computedEndTime {
    final startMinutes = _selectedStartTimeMinutes;
    if (startMinutes == null || _totalDurationMinutes <= 0) {
      return _emptyTimeLabel;
    }

    return _formatTimeFromMinutes(startMinutes + _totalDurationMinutes);
  }

  String _buildDurationSummaryLabel() {
    if (_selectedServices.isEmpty) {
      return AppStrings.appointmentNoServicesSelected;
    }

    return '${AppStrings.appointmentDurationSummaryPrefix} '
        '${formatServiceDuration(_totalDurationMinutes)}';
  }

  String? _buildAppointmentSummaryLabel() {
    if (_selectedServices.isEmpty) {
      return null;
    }

    final count = _selectedServices.length;
    final countLabel = count == 1 ? '1 serviço' : '$count serviços';
    final parts = <String>[
      countLabel,
      formatServiceDuration(_totalDurationMinutes),
    ];

    final totalPrice = _totalPrice;
    if (_hasSelectedServicePrices && totalPrice != null) {
      parts.add(formatServicePrice(totalPrice));
    }

    return parts.join(' • ');
  }

  String _formatTimeFromMinutes(int totalMinutes) {
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  void _addService(Service service) {
    final alreadySelected = _selectedServices.any(
      (selectedService) => selectedService.id == service.id,
    );

    if (alreadySelected) {
      _showMessage(AppStrings.appointmentServiceAlreadyAdded);
      return;
    }

    setState(() {
      _selectedServices = [..._selectedServices, service];
      _servicesError = null;
    });
  }

  void _removeService(Service service) {
    setState(
      () => _selectedServices = _selectedServices
          .where((selectedService) => selectedService.id != service.id)
          .toList(growable: false),
    );
  }

  void _replaceService(int index, Service newService) {
    final isDuplicate = _selectedServices.asMap().entries.any(
          (entry) =>
              entry.key != index && entry.value.id == newService.id,
        );

    if (isDuplicate) {
      _showMessage(AppStrings.appointmentServiceAlreadyAdded);
      return;
    }

    setState(() {
      final updatedServices = List<Service>.from(_selectedServices);
      updatedServices[index] = newService;
      _selectedServices = updatedServices;
      _servicesError = null;
    });
  }

  Future<void> _openSelectedServiceActions(Service service, int index) async {
    final action = await showModalBottomSheet<AppointmentSelectedServiceAction>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) =>
          AppointmentSelectedServiceActionsBottomSheet(service: service),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case AppointmentSelectedServiceAction.replace:
        await _openServicePickerForReplace(index);
      case AppointmentSelectedServiceAction.remove:
        _removeService(service);
    }
  }

  Future<void> _openServicePickerForReplace(int index) async {
    final service = await showModalBottomSheet<Service>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const ServicePickerBottomSheet(),
    );

    if (!mounted || service == null) return;

    _replaceService(index, service);
  }

  Future<void> _openClientPicker() async {
    final client = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const ClientPickerBottomSheet(),
    );

    if (!mounted || client == null) return;

    setState(() {
      _selectedClient = client;
      _clientError = null;
    });
  }

  Future<void> _openServicePicker() async {
    final service = await showModalBottomSheet<Service>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const ServicePickerBottomSheet(),
    );

    if (!mounted || service == null) return;

    _addService(service);
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.9;

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: AppColors.warmWhite,
            borderRadius: AppRadius.borderTopLg,
            boxShadow: AppShadows.level2,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  const AppointmentBottomSheetHandle(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: AppSpacing.screenPadding.copyWith(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppointmentFormHeader(onClose: _close),
                          const SizedBox(height: AppSpacing.lg),
                          KeyedSubtree(
                            key: _clientSectionKey,
                            child: AppointmentClientSection(
                              selectedClient: _selectedClient,
                              errorText: _clientError,
                              onTap: _openClientPicker,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          KeyedSubtree(
                            key: _servicesSectionKey,
                            child: AppointmentServicesSection(
                              selectedServices: _selectedServices,
                              errorText: _servicesError,
                              onAddService: _openServicePicker,
                              onServiceTap: _openSelectedServiceActions,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          KeyedSubtree(
                            key: _professionalSectionKey,
                            child: AppointmentProfessionalSection(
                              professionalName: _selectedProfessionalName,
                              professionalSpecialty:
                                  _selectedProfessionalSpecialty,
                              errorText: _professionalError,
                              onTap: () => _showMessage(
                                AppStrings
                                    .appointmentSelectProfessionalComingSoon,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          KeyedSubtree(
                            key: _dateTimeSectionKey,
                            child: AppointmentDateTimeSection(
                              dateLabel: _selectedDateLabel,
                              dateError: _dateError,
                              startTimeValue: _startTimeDisplay,
                              endTimeValue: _computedEndTime,
                              startTimeError: _startTimeError,
                              durationSummaryLabel: _buildDurationSummaryLabel(),
                              appointmentSummaryLabel:
                                  _buildAppointmentSummaryLabel(),
                              onDateTap: () => _showMessage(
                                AppStrings.appointmentSelectDateComingSoon,
                              ),
                              onStartTimeTap: () => _showMessage(
                                AppStrings.appointmentSelectTimeComingSoon,
                              ),
                              onEndTimeTap: () => _showMessage(
                                AppStrings.appointmentSelectTimeComingSoon,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppointmentNotesSection(controller: _notesController),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: AppStrings.appointmentConfirm,
                            icon: Icons.check_circle_outline_rounded,
                            onPressed: _confirmAppointment,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
