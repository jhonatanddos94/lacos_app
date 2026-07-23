import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lacos_app/app/app.dart';
import 'package:lacos_app/core/config/app_durations.dart';
import 'package:lacos_app/core/config/app_strings.dart';
import 'package:lacos_app/core/formatters/appointment_display_formatters.dart';
import 'package:lacos_app/core/formatters/service_display_formatters.dart';
import 'package:lacos_app/core/theme/app_colors.dart';
import 'package:lacos_app/core/theme/app_radius.dart';
import 'package:lacos_app/core/theme/app_shadows.dart';
import 'package:lacos_app/core/theme/app_spacing.dart';
import 'package:lacos_app/features/agenda/application/agenda_day.dart';
import 'package:lacos_app/features/appointments/application/models/appointment_details.dart';
import 'package:lacos_app/features/appointments/application/providers/appointment_providers.dart';
import 'package:lacos_app/features/appointments/domain/entities/appointment.dart';
import 'package:lacos_app/features/appointments/presentation/appointment_form_mode.dart';
import 'package:lacos_app/features/appointments/presentation/bottom_sheets/appointment_selected_service_actions_bottom_sheet.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_availability_calculator.dart';
import 'package:lacos_app/features/appointments/presentation/helpers/appointment_form_initial_date.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_client_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_date_time_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_form_header.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_notes_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_professional_section.dart';
import 'package:lacos_app/features/appointments/presentation/widgets/appointment_services_section.dart';
import 'package:lacos_app/features/clients/domain/entities/client.dart';
import 'package:lacos_app/features/clients/presentation/bottom_sheets/client_picker_bottom_sheet.dart';
import 'package:lacos_app/features/professional/domain/entities/professional.dart';
import 'package:lacos_app/features/professional/presentation/bottom_sheets/professional_picker_bottom_sheet.dart';
import 'package:lacos_app/features/services/domain/entities/service.dart';
import 'package:lacos_app/features/services/presentation/bottom_sheets/service_picker_bottom_sheet.dart';
import 'package:lacos_app/shared/widgets/buttons/app_button.dart';

class AppointmentFormBottomSheet extends ConsumerStatefulWidget {
  const AppointmentFormBottomSheet({
    this.mode = AppointmentFormMode.create,
    this.initialData,
    this.initialDate,
    super.key,
  }) : assert(
         mode == AppointmentFormMode.create || initialData != null,
         'initialData is required for edit mode',
       );

  final AppointmentFormMode mode;
  final AppointmentDetails? initialData;
  final DateTime? initialDate;

  @override
  ConsumerState<AppointmentFormBottomSheet> createState() =>
      _AppointmentFormBottomSheetState();
}

class _AppointmentFormBottomSheetState
    extends ConsumerState<AppointmentFormBottomSheet> {
  static const _emptyTimeLabel = '--:--';
  static const _availabilityCalculator = AppointmentAvailabilityCalculator();

  final _scrollController = ScrollController();
  final _clientSectionKey = GlobalKey();
  final _servicesSectionKey = GlobalKey();
  final _professionalSectionKey = GlobalKey();
  final _dateTimeSectionKey = GlobalKey();

  final _notesController = TextEditingController();
  Client? _selectedClient;
  List<Service> _selectedServices = [];
  Professional? _selectedProfessional;
  DateTime? _selectedDate;
  int? _selectedStartTimeMinutes;

  String? _clientError;
  String? _servicesError;
  String? _professionalError;
  String? _dateError;
  String? _startTimeError;
  String? _saveError;

  bool get _isEditMode => widget.mode == AppointmentFormMode.edit;

  String get _formTitle => _isEditMode
      ? AppStrings.appointmentFormEditTitle
      : AppStrings.appointmentFormCreateTitle;

  String? get _formSubtitle =>
      _isEditMode ? null : AppStrings.newAppointmentSubtitle;

  String get _submitLabel => _isEditMode
      ? AppStrings.appointmentFormEditAction
      : AppStrings.appointmentFormCreateAction;

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      _prefillFromInitialData(widget.initialData!);
    } else {
      _selectedDate = resolveAppointmentFormInitialSelectedDate(
        mode: widget.mode,
        initialDate: widget.initialDate,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_isEditMode) {
        ref.read(updateAppointmentControllerProvider.notifier).reset();
      } else {
        ref.read(createAppointmentControllerProvider.notifier).reset();
      }
    });
  }

  void _prefillFromInitialData(AppointmentDetails details) {
    final startAt = details.appointment.startAt;

    _selectedClient = details.client;
    _selectedServices = List<Service>.from(details.services);
    _selectedProfessional = details.professional;
    _selectedDate = normalizeAppointmentDate(startAt);
    _selectedStartTimeMinutes = startAt.hour * 60 + startAt.minute;

    final notes = details.notes?.trim();
    if (notes != null && notes.isNotEmpty) {
      _notesController.text = notes;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _close() {
    if (ref.read(createAppointmentControllerProvider).isLoading ||
        ref.read(updateAppointmentControllerProvider).isLoading) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    if (_isEditMode) {
      if (ref.read(updateAppointmentControllerProvider).isLoading) return;

      setState(() => _saveError = null);

      final updatedAppointment = await ref
          .read(updateAppointmentControllerProvider.notifier)
          .save(
            appointmentId: widget.initialData!.appointment.id,
            clientId: _selectedClient!.id,
            professionalId: _selectedProfessional!.id,
            services: _selectedServices,
            startAt: _buildStartAt(),
            endAt: _buildEndAt(),
            notes: _notesController.text.trim(),
          );

      if (!mounted) return;

      if (updatedAppointment != null) {
        Navigator.of(context).pop(updatedAppointment);
        return;
      }

      final errorMessage = _resolveSaveErrorMessage();
      if (errorMessage != null) {
        debugPrint('[AppointmentUpdate] failed: $errorMessage');
        setState(() => _saveError = errorMessage);
        _showMessage(errorMessage);
      }
      return;
    }

    if (ref.read(createAppointmentControllerProvider).isLoading) return;

    setState(() => _saveError = null);

    final createdAppointment = await ref
        .read(createAppointmentControllerProvider.notifier)
        .save(
          clientId: _selectedClient!.id,
          professionalId: _selectedProfessional!.id,
          services: _selectedServices,
          startAt: _buildStartAt(),
          endAt: _buildEndAt(),
          existingAppointments: _readDayAppointments(),
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    if (createdAppointment != null) {
      Navigator.of(context).pop(createdAppointment);
      return;
    }

    final errorMessage = _resolveSaveErrorMessage();
    if (errorMessage != null) {
      debugPrint('[AppointmentSave] failed: $errorMessage');
      setState(() => _saveError = errorMessage);
      _showMessage(errorMessage);
    }
  }

  bool get _isSelectedStartTimeInPast {
    if (_selectedDate == null || _selectedStartTimeMinutes == null) {
      return false;
    }

    return _buildStartAt().isBefore(DateTime.now());
  }

  DateTime _buildStartAt() {
    final date = _selectedDate!;
    final startMinutes = _selectedStartTimeMinutes!;

    return DateTime(
      date.year,
      date.month,
      date.day,
      startMinutes ~/ 60,
      startMinutes % 60,
    );
  }

  DateTime _buildEndAt() {
    return _buildStartAt().add(Duration(minutes: _totalDurationMinutes));
  }

  List<Appointment> _readDayAppointments() {
    final date = _selectedDate;
    if (date == null) return const [];

    return ref.read(appointmentsByDayProvider(AgendaDay.from(date))).value ??
        const [];
  }

  String? _resolveSaveErrorMessage() {
    final error = _isEditMode
        ? ref.read(updateAppointmentControllerProvider).error
        : ref.read(createAppointmentControllerProvider).error;

    return switch (error) {
      FormatException(message: final message) => message,
      _ =>
        _isEditMode
            ? AppStrings.appointmentUpdateError
            : AppStrings.appointmentSaveError,
    };
  }

  bool _validateForm() {
    final clientError = _selectedClient == null
        ? AppStrings.appointmentClientRequired
        : null;
    final servicesError = _selectedServices.isEmpty
        ? AppStrings.appointmentAddAtLeastOneService
        : null;
    final professionalError = _selectedProfessional == null
        ? AppStrings.appointmentProfessionalRequired
        : null;
    final dateError = _selectedDate == null
        ? AppStrings.appointmentDateRequired
        : null;
    final startTimeError = _selectedStartTimeMinutes == null
        ? AppStrings.appointmentStartTimeRequired
        : (!_isEditMode && _isSelectedStartTimeInPast)
        ? AppStrings.appointmentStartAtInPast
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

  bool get _canCalculateAvailableTimes {
    return _selectedDate != null &&
        _selectedProfessional != null &&
        _selectedServices.isNotEmpty &&
        _totalDurationMinutes > 0;
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

  DateTime get _todayDate => normalizeAppointmentDate(DateTime.now());

  DateTime get _tomorrowDate =>
      normalizeAppointmentDate(DateTime.now().add(const Duration(days: 1)));

  String? get _selectedDateDisplayLabel {
    final date = _selectedDate;
    if (date == null) return null;
    return formatAppointmentDateLabel(date);
  }

  bool get _isTodaySelected {
    final date = _selectedDate;
    return date != null && isSameAppointmentDate(date, _todayDate);
  }

  bool get _isTomorrowSelected {
    final date = _selectedDate;
    return date != null && isSameAppointmentDate(date, _tomorrowDate);
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
      (entry) => entry.key != index && entry.value.id == newService.id,
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

  Future<void> _openProfessionalPicker() async {
    final professional = await showModalBottomSheet<Professional>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderTopLg),
      builder: (context) => const ProfessionalPickerBottomSheet(),
    );

    if (!mounted || professional == null) return;

    setState(() {
      _selectedProfessional = professional;
      _professionalError = null;
    });
  }

  void _setSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = normalizeAppointmentDate(date);
      _dateError = null;
    });
  }

  void _selectToday() {
    _setSelectedDate(_todayDate);
  }

  void _selectTomorrow() {
    _setSelectedDate(_tomorrowDate);
  }

  Future<void> _openDatePicker() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? _todayDate;
    final firstDate = _todayDate;

    final pickedDate = await showDatePicker(
      context: context,
      locale: LacosApp.appLocale,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    if (!mounted || pickedDate == null) return;

    _setSelectedDate(pickedDate);
  }

  void _setSelectedStartTime(int totalMinutes) {
    setState(() {
      _selectedStartTimeMinutes = totalMinutes;
      _startTimeError = null;
    });
  }

  void _retryLoadAvailableTimes() {
    final date = _selectedDate;
    if (date == null) return;
    ref.invalidate(appointmentsByDayProvider(AgendaDay.from(date)));
  }

  List<Appointment> _filterDayAppointmentsForAvailability(
    List<Appointment> appointments,
  ) {
    if (!_isEditMode) return appointments;

    final appointmentId = widget.initialData?.appointment.id;
    if (appointmentId == null) return appointments;

    return appointments
        .where((appointment) => appointment.id != appointmentId)
        .toList(growable: false);
  }

  List<DateTime> _calculateAvailableStartTimes(
    List<Appointment> dayAppointments,
  ) {
    final date = _selectedDate!;
    final professional = _selectedProfessional!;

    return _availabilityCalculator.calculateAvailableStartTimes(
      day: date,
      durationMinutes: _totalDurationMinutes,
      dayAppointments: _filterDayAppointmentsForAvailability(dayAppointments),
      professionalId: professional.id,
    );
  }

  void _invalidateSelectedTimeIfNoLongerAvailable(
    List<DateTime> availableStartTimes,
  ) {
    final selected = _selectedStartTimeMinutes;
    if (selected == null) return;

    final isAvailable = AppointmentAvailabilityCalculator.isStartTimeAvailable(
      startTimeMinutes: selected,
      availableStartTimes: availableStartTimes,
    );
    if (isAvailable) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedStartTimeMinutes != selected) return;
      setState(() => _selectedStartTimeMinutes = null);
      _showMessage(AppStrings.appointmentSelectedTimeNoLongerAvailable);
    });
  }

  Future<void> _openTimePicker(List<DateTime> availableStartTimes) async {
    final initialTime = _selectedStartTimeMinutes == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(
            hour: _selectedStartTimeMinutes! ~/ 60,
            minute: _selectedStartTimeMinutes! % 60,
          );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (!mounted || pickedTime == null) return;

    final pickedMinutes = pickedTime.hour * 60 + pickedTime.minute;
    final isAvailable = AppointmentAvailabilityCalculator.isStartTimeAvailable(
      startTimeMinutes: pickedMinutes,
      availableStartTimes: availableStartTimes,
    );

    if (!isAvailable) {
      _showMessage(AppStrings.appointmentCustomTimeUnavailable);
      return;
    }

    _setSelectedStartTime(pickedMinutes);
  }

  @override
  Widget build(BuildContext context) {
    var isLoadingAvailableTimes = false;
    String? availabilityError;
    List<int> displayedStartTimeMinutes = const [];
    List<DateTime> availableStartTimes = const [];
    var showNoAvailableTimesMessage = false;

    if (_canCalculateAvailableTimes) {
      final appointmentsAsync = ref.watch(
        appointmentsByDayProvider(AgendaDay.from(_selectedDate!)),
      );

      appointmentsAsync.when(
        data: (dayAppointments) {
          availableStartTimes = _calculateAvailableStartTimes(dayAppointments);
          displayedStartTimeMinutes = _availabilityCalculator
              .toDisplayedStartTimeMinutes(availableStartTimes);
          showNoAvailableTimesMessage = availableStartTimes.isEmpty;
          _invalidateSelectedTimeIfNoLongerAvailable(availableStartTimes);
        },
        loading: () => isLoadingAvailableTimes = true,
        error: (_, _) {
          availabilityError = AppStrings.appointmentAvailabilityLoadError;
        },
      );
    }

    final isSaving = _isEditMode
        ? ref.watch(updateAppointmentControllerProvider).isLoading
        : ref.watch(createAppointmentControllerProvider).isLoading;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.9;

    return PopScope(
      canPop: !isSaving,
      child: GestureDetector(
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
                            AppointmentFormHeader(
                              title: _formTitle,
                              subtitle: _formSubtitle,
                              onClose: isSaving ? null : _close,
                            ),
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
                                selectedProfessional: _selectedProfessional,
                                errorText: _professionalError,
                                onTap: _openProfessionalPicker,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            KeyedSubtree(
                              key: _dateTimeSectionKey,
                              child: AppointmentDateTimeSection(
                                dateDisplayLabel: _selectedDateDisplayLabel,
                                hasSelectedDate: _selectedDate != null,
                                isTodaySelected: _isTodaySelected,
                                isTomorrowSelected: _isTomorrowSelected,
                                dateError: _dateError,
                                startTimeValue: _startTimeDisplay,
                                endTimeValue: _computedEndTime,
                                selectedStartTimeMinutes:
                                    _selectedStartTimeMinutes,
                                startTimeError: _startTimeError,
                                durationSummaryLabel:
                                    _buildDurationSummaryLabel(),
                                appointmentSummaryLabel:
                                    _buildAppointmentSummaryLabel(),
                                canCalculateAvailableTimes:
                                    _canCalculateAvailableTimes,
                                isLoadingAvailableTimes:
                                    isLoadingAvailableTimes,
                                availabilityError: availabilityError,
                                displayedStartTimeMinutes:
                                    displayedStartTimeMinutes,
                                showNoAvailableTimesMessage:
                                    showNoAvailableTimesMessage,
                                onDateTap: _openDatePicker,
                                onTodayTap: _selectToday,
                                onTomorrowTap: _selectTomorrow,
                                onSelectStartTime: _setSelectedStartTime,
                                onCustomStartTimeTap: () =>
                                    _openTimePicker(availableStartTimes),
                                onRetryAvailability: _canCalculateAvailableTimes
                                    ? _retryLoadAvailableTimes
                                    : null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppointmentNotesSection(
                              controller: _notesController,
                            ),
                            if (_saveError != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _saveError!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            AppButton(
                              label: _submitLabel,
                              icon: Icons.check_circle_outline_rounded,
                              isLoading: isSaving,
                              onPressed: isSaving ? null : _submitForm,
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
      ),
    );
  }
}
